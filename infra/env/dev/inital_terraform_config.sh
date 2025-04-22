#!/bin/bash -u
# Usage: $0 [options]
#
# Options:
#   [-s | --system_name] var                  System Name
#   [-e | --environment] var                  Environment Name
#   [-d | --config_delete]

#
# This script sets up the initial Terraform configuration for the development environment.
# It creates an S3 bucket to store the Terraform state file and generates a backend configuration file for Terraform.
# The script also includes commented-out sections for creating a DynamoDB table, which is currently not in use.

# Variables:
# - environment: The current working directory name, used as the environment name.
# - region_name: The AWS region where resources will be created.
# - account_id: The AWS account ID retrieved using AWS STS.
# - bucket_name: The name of the S3 bucket for storing the Terraform state file.
# - policy_file: The name of the JSON file containing the S3 bucket policy.
# - terraform_backend_file: The name of the file containing the Terraform backend configuration.

# Functions:
# - create_bucket_policy: Generates an S3 bucket policy that denies unencrypted transport.
# - create_s3_bucket: Creates the S3 bucket if it does not already exist and applies the bucket policy.
# - create_tfbackend: Generates the Terraform backend configuration file.

# Main function:
# - Calls the create_s3_bucket function to ensure the S3 bucket is created.
# - Calls the create_tfbackend function to generate the Terraform backend configuration file.
# - Prints the S3 bucket name and environment name.

# Note: The script includes commented-out sections for creating a DynamoDB table, which are currently not executed.

# 変数設定
SCRIPT_DIR=$(cd $(dirname $0); pwd)
policy_file=${SCRIPT_DIR}"/s3_bucket_policy.json"
terraform_backend_file=${SCRIPT_DIR}"/terraform.tfbackend"

#
# dynamodbの廃止
#
#dynamodb_table="tfstate-lock"
#dynamodb_hash_key="LockID"
#dynamodb_attribute="AttributeName=${dynamodb_hash_key},AttributeType=S"
#dynamodb_keyschema="AttributeName=${dynamodb_hash_key},KeyType=HASH"
#dynamodb_provisioned="ReadCapacityUnits=1,WriteCapacityUnits=1"

function usage()
{
  sed -rn '/^# Usage/,${/^#/!q;s/^# ?//;p}' "${SCRIPT_DIR}/${progname}" |
  sed -r "s/\\\$0/$(basename ${progname})/"
  exit 1
}

function flag_check()
{
  if ! validAlphaNum "$1" ; then
    echo "Argument error. : $1"
    usage
    exit 1
  fi
}

validAlphaNum() 
{ 
  # 引数が英数字だけの文字列なら 0 を返し、そうでない場合には 1 を返す． 
  # 英数字以外の文字をすべて削除する． 
  compressed="$(echo $1 | sed -e 's/[^[:alnum:]-]//g')"

  if [ "$compressed" != "$1" ] ; then 
    return 1 
  else 
    return 0 
  fi 
} 

function create_bucket_policy () {
cat << EOF > ${policy_file}
{
    "Version": "2012-10-17",
    "Id": "Policy1676956538318",
    "Statement": [
        {
            "Sid": "Stmt1676956534343",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${bucket_name}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOF
}

function create_s3_bucket () {
    # S3バケット作成
    if [ -z "${system_name}" ]; then
        bucket_name="tfstate-"${account_id}
    else
        bucket_name="tfstate-"${system_name,,}-"${account_id}"
    fi
    aws s3 ls "s3://"${bucket_name} > /dev/null 2>&1
    if [ $? == 254 ]; then
        echo create s3 bucket : ${bucket_name}
        create_bucket_policy
        aws s3 mb s3://${bucket_name} --region ${region_name}
        aws s3api put-bucket-policy --bucket ${bucket_name} --policy file://${policy_file}
    fi
}

function config_delete () {
    echo "Do you want to initialize internet.tfvars and localnet.tfvars file? [yes/no]"
    read answer
    if [ "${answer}" = "yes" ]; then
        rm -f ${SCRIPT_DIR}/internet.tfvars
        rm -f ${SCRIPT_DIR}/localnet.tfvars
    fi
}

#
# dynamodbの廃止
#
#function create_dynamodb_table () {
#    # DynamoDBのテーブル作成
#    aws dynamodb describe-table --table-name ${dynamodb_table} --region ${region_name} > /dev/null 2>&1
#    if [ $? == 254 ]; then
#        echo create dynamodb table : ${dynamodb_table}
#        aws dynamodb create-table --table-name ${dynamodb_table} \
#                                  --attribute-definitions ${dynamodb_attribute} \
#                                  --key-schema ${dynamodb_keyschema} \
#                                  --provisioned-throughput ${dynamodb_provisioned} \
#                                  --region ${region_name} \
#                                  --no-cli-pager
#    fi
#}

function create_tfbackend () {
cat << EOF > ${terraform_backend_file}
bucket         = "${bucket_name}"
key            = "${environment}/terraform.tfstate"
region         = "${region_name}"
encrypt        = true
EOF
}
#
# dynamodbの廃止
#
# dynamodb_table = "${dynamodb_table}"

function get_arguments() {
  short_opt_str='s:e:dh'
  long_opt_str='system_name:,environment:,config_delete,help'
  progname=$(basename ${BASH_SOURCE[0]:-$0})
  OPTS=$(getopt -o "${short_opt_str}" -l "${long_opt_str}" -n "${progname}" -- "$@")
  if [ $? -ne 0 ]; then
    echo "Argument error."
    usage
    exit 1
  fi
  #if [ $# -eq 0 ]; then
  #  usage
  #fi
  eval set -- "$OPTS"
  unset OPTS
  while true; do
    case "$1" in
      '-s'|'--system_name')
        system_name=$2
        flag_check "${system_name}"
        shift 2
        ;;
      '-e'|'--environment')
        environment=$2
        flag_check "${environment}"
        shift 2
        ;;
      '-d'|'--config_delete')
        config_delete
        shift 1
        ;;
      '-h'|'--help')
        usage
        exit 1
        shift
        ;;
      '--')
        shift
        break
        ;;
    esac
  done
}

function main () {
    if [ -s ${SCRIPT_DIR}/system_config ]; then
        source ${SCRIPT_DIR}/system_config
        flag_check "${system_name}"
    fi
    if [ -z "${environment}" ]; then
        environment=$(basename ${SCRIPT_DIR})
    fi
    aws sts get-caller-identity > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        account_id=$(aws sts get-caller-identity | jq -r ".Account")
    else
        echo "Failed to get AWS account ID."
        exit 1
    fi
    get_arguments "$@"
    if [ ${#system_name} -gt 19 ]; then
        echo "system_name is too long. (max 19 characters)"
        exit 1
    fi
    if [ ${#environment} -gt 3 ]; then
        echo "environment is too long. (max 3 characters)"
        exit 1
    fi
    create_s3_bucket
    echo "terraform system_name    : ${system_name}"
    #
    # dynamodbの廃止
    #
    # create_dynamodb_table
    create_tfbackend
    echo "terraform s3 backet      : ${bucket_name}"
    #
    # dynamodbの廃止
    #
    # echo "terraform dynamodb table : ${dynamodb_table}"
    echo "terraform environment    : ${environment}"
    # terraform.tfvarsの作成
    if [ ! -s ${SCRIPT_DIR}/internet.tfvars ]; then
        cp -p ${SCRIPT_DIR}/internet.tfvars.template ${SCRIPT_DIR}/internet.tfvars
        if [ -z "${internet}" ]; then
            sed -i "s/__systemname__/${system_name}/g" ${SCRIPT_DIR}/internet.tfvars
        else
            sed -i "s/__systemname__/${internet}/g" ${SCRIPT_DIR}/internet.tfvars
        fi
        sed -i "s/__environment__/${environment}/g" ${SCRIPT_DIR}/internet.tfvars
    fi
    if [ ! -s ${SCRIPT_DIR}/localnet.tfvars ]; then
        cp -p ${SCRIPT_DIR}/localnet.tfvars.template ${SCRIPT_DIR}/localnet.tfvars
        if [ -z "${localnet}" ]; then
            sed -i "s/__systemname__/${system_name}/g" ${SCRIPT_DIR}/localnet.tfvars
        else
            sed -i "s/__systemname__/${localnet}/g" ${SCRIPT_DIR}/localnet.tfvars
        fi
        sed -i "s/__environment__/${environment}/g" ${SCRIPT_DIR}/localnet.tfvars
    fi

}

main "$@"