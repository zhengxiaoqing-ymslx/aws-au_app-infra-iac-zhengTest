###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/10/30
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 各環境毎の環境変数に値いを設定する。
# 設定する内容は、以下の物とする。
# - AWS VPC関連の基本情報（リージョン、VPC ID、Subnet ID等）
# - システム関連（名称、環境等）
#
###############################################################################

#
# AWS VPC関連の基本情報（VPC ID、Subnet ID等）
#
aws_region_name           = "ap-northeast-1"
aws_vpc_id                = "vpc-0fc56c69d8cca3803"
aws_vpc_cidr              = "10.0.0.0/16"
aws_vpc_s3_endpoint       = "vpce-00771936dee0bb65d"
aws_subnet_public-a_id    = "subnet-0cb7576f339a2e0c8"
aws_subnet_public-c_id    = "subnet-08ffef56f7c9aa937"
aws_subnet_protected-a_id = "subnet-000cfd6f239ee1909"
aws_subnet_protected-c_id = "subnet-0a5aba6ec5b0928c5"
aws_subnet_private-a_id   = "subnet-0b074b02323e045ea"
aws_subnet_private-c_id   = "subnet-0c2b650e6571ad02a"

#
# システム名称
#
#              1234567890123456789 (制限:19文字以内)
system_name = "YMSLSandboxLocal"

#              123 (制限:3文字以内)
environment = "dev"

#
# Database設定
#
# RDSの種類選択("rds" or "aurora")
db_type = "rds"

#
# RDS設定
#
aws_rds_storage  = 20
aws_rds_multi_az = false

#
# Aurora設定
#
aws_aurora_instance_count = 1 # single:1 multi_az:2

#
# EC2設定
#
aws_ec2_create_flag = false

#
# ECR設定
#
aws_ecr_repository = "basic-app-backend"

#
# ECS設定
#
app_profiles_active = "production"
app_db_url          = "jdbc:postgresql://dev-ymslsandboxtest1234-rds.c25vsfxqhmp7.ap-northeast-1.rds.amazonaws.com:5432/basicapp"

#
# ALB設定
#
backend_app_port = 8080
aws_alb_acm_arn  = "arn:aws:acm:ap-northeast-1:072438257795:certificate/28ec44b1-09af-485d-aca1-1942caee406d"
alb_domain_name  = "api.admin.km2-education.com"
#
# 社内LAN公開用の環境設定
# 
aws_alb_internal = true # 社内LAN公開する場合は、trueに設定 

#
# OIDC設定
#
oidc_flag          = false
organizations_name = "YMC-GROUP"
repository_name    = "aws-au_app-infra-iac"

#
# cloudfront設定
#
app_domain_name = "www.admin.km2-education.com"
aws_cf_acm_arn  = "arn:aws:acm:us-east-1:072438257795:certificate/be1f4d1e-fc7b-4707-8d32-d4498bf83242"

#
# S3設定
#
aws_s3_bucket_versioning = "Disabled" # "Enabled" or "Disabled"
