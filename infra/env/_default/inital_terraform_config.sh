#!/bin/bash

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
environment=$(basename `pwd`)
region_name="ap-northeast-1"
account_id=$(aws sts get-caller-identity | jq -r ".Account")
bucket_name="tfstate-"${account_id}
policy_file="s3_bucket_policy.json"
terraform_backend_file="terraform.tfbackend"
#
# dynamodbの廃止
#
#dynamodb_table="tfstate-lock"
#dynamodb_hash_key="LockID"
#dynamodb_attribute="AttributeName=${dynamodb_hash_key},AttributeType=S"
#dynamodb_keyschema="AttributeName=${dynamodb_hash_key},KeyType=HASH"
#dynamodb_provisioned="ReadCapacityUnits=1,WriteCapacityUnits=1"

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
    aws s3 ls "s3://"${bucket_name} > /dev/null 2>&1
    if [ $? == 254 ]; then
        echo create s3 bucket : ${bucket_name}
        create_bucket_policy
        aws s3 mb s3://${bucket_name} --region ${region_name}
        aws s3api put-bucket-policy --bucket ${bucket_name} --policy file://${policy_file}
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


function main () {
    create_s3_bucket
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
}

main