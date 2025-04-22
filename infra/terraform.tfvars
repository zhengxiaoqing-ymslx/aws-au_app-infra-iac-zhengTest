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
aws_vpc_id                = "vpc-0464709b4e7cea225"
aws_vpc_cidr              = "192.168.0.0/16"
aws_vpc_s3_endpoint       = "vpce-00771936dee0bb65d"
aws_subnet_public-a_id    = "subnet-05da79948f4543e55"
aws_subnet_public-c_id    = "subnet-00d241812671a7e4a"
aws_subnet_protected-a_id = "subnet-0076bbde9df5906fe"
aws_subnet_protected-c_id = "subnet-05a034287d4733439"
aws_subnet_private-a_id   = "subnet-0deb9b8a543410034"
aws_subnet_private-c_id   = "subnet-02e87f45d9a38f3fd"

#
# システム名称
#
#              1234567890123456789 (制限:19文字以内)
system_name = "YMSLSandbox"

#              123 (制限:3文字以内)
environment = "dev"

#
# Database設定
#
db_name     = "postgres"
db_username = "postgres"
db_port     = 5432
# RDSの種類選択("rds" or "aurora")
db_type = "rds"

#
# RDS設定
#
aws_rds_db_engine_ver = "15.7"
aws_rds_instance_type = "db.t3.micro"
aws_rds_storage       = 20
aws_rds_multi_az      = false
aws_rds_family        = "postgres15"

#
# Aurora設定
#
aws_aurora_db_engine_ver  = "15.4"
aws_aurora_instance_type  = "db.t3.medium"
aws_aurora_instance_count = 1 # single:1 multi_az:2
aws_aurora_family         = "aurora-postgresql15"

# EC2設定
#
aws_ami               = "ami-03f584e50b2d32776"
aws_ec2_instance_type = "t3.micro"
aws_ec2_create_flag   = true

#
# ECR設定
#
aws_ecr_repository = "basic-app-backend"

#
# ECS設定
#
app_name            = "yna-g3-solid"
app_profiles_active = "production"
app_db_username     = "basicapp"
app_db_url          = "jdbc:postgresql://dev-ymslsandboxtest1234-rds.c25vsfxqhmp7.ap-northeast-1.rds.amazonaws.com:5432/basicapp"
app_cpu             = 1024
app_memory          = 2048
# コンテナイメージ未作成の為、taskを起動しない設定(タスク数:0)
ecs_desired_count                     = 0
ecs_health_check_grace_period_seconds = 60
ecs_force_new_deployment              = true
ecs_taskdef_healthcheck               = ["CMD-SHELL", "curl -f http://localhost:8080/basicapp/public/getApCheck.json || exit 1"]
ecs_exec_flag                         = true
# コンテナイメージのrootファイルシステムを読み書き可に設定する場合に有効化
ecs_readonlyRootFilesystem            = false
ecs_mount_points                      = "[]"
# コンテナイメージのrootファイルシステムを読み取り専用に設定する場合に有効化
# ecs_readonlyRootFilesystem            = true
# ecs_mount_points                      = <<EOF
# [
#     {
#         "sourceVolume": "YNA-G3-logs",
#         "containerPath": "/workspace/logs",
#         "readOnly": false
#     },
#     {
#         "sourceVolume": "YNA-G3-tmp",
#         "containerPath": "/workspace/tmp",
#         "readOnly": false
#     },
#     {
#         "sourceVolume": "YNA-G3-amazon-lib",
#         "containerPath": "/var/lib/amazon",
#         "readOnly": false
#     },
#     {
#         "sourceVolume": "YNA-G3-amazon-log",
#         "containerPath": "/var/log/amazon",
#         "readOnly": false
#     }
# ]
# EOF

#
# ALB設定
#
backend_app_port              = 8080
aws_alb_acm_arn               = "arn:aws:acm:ap-northeast-1:072438257795:certificate/28ec44b1-09af-485d-aca1-1942caee406d"
alb_domain_name               = "api.admin.km2-education.com"
alb_backend_uri               = "/basicapp/*"
alb_backend_health_check_path = "/basicapp/HelloWorld"
#
# 社内LAN公開用の環境設定
# 
aws_alb_internal               = false # 社内LAN公開する場合は、trueに設定 
alb_frontend_health_check_path = "/index.html"
frontend_app_port              = 8080

#
# OIDC設定
#
oidc_flag                   = false
frontend_organizations_name = "YMSL-J"
frontend_repository_name    = "basic-app-frontend"
backend_organizations_name  = "YMSL-J"
backend_repository_name     = "basic-app-backend"


#
# cloudfront設定
#
# 代替ドメインは、www付きと無しの２種類が登録されます。
# app_domain_nameで指定するのは、wwwなしのドメイン名を登録願います。
app_domain_name = "www.admin.km2-education.com"
aws_cf_acm_arn  = "arn:aws:acm:us-east-1:072438257795:certificate/be1f4d1e-fc7b-4707-8d32-d4498bf83242"

#
# S3設定
#
aws_s3_bucket_versioning = "Disabled" # "Enabled" or "Disabled"
