###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/10/30
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 各環境毎の環境変数を定義する。
# 定義する内容は、以下の物とする。
# - AWS VPC関連の基本情報（リージョン、VPC ID、Subnet ID等）
# - システム名称
#
###############################################################################

#
# AWS VPC関連の基本情報（VPC ID、Subnet ID等）
#
variable "aws_region_name" {}
variable "aws_vpc_id" {}
variable "aws_vpc_cidr" {}
variable "aws_vpc_s3_endpoint" {}
variable "aws_subnet_public-a_id" {}
variable "aws_subnet_public-c_id" {}
variable "aws_subnet_protected-a_id" {}
variable "aws_subnet_protected-c_id" {}
variable "aws_subnet_private-a_id" {}
variable "aws_subnet_private-c_id" {}

#
# システム名称
#
variable "system_name" {
  type        = string
  description = "A simple example of the module variable validation."

  validation {
    condition     = length(var.system_name) <= 19
    error_message = "The validation_example value length must be <= 19."
  }
}
variable "environment" {
  type        = string
  description = "A simple example of the module variable validation."

  validation {
    condition     = length(var.environment) <= 3
    error_message = "The validation_example value length must be <= 3."
  }
}

#
# Database設定
#
variable "db_name" {}
variable "db_username" {}
variable "db_port" {}
variable "db_type" {}

#
# RDS設定
#
variable "aws_rds_db_engine_ver" {}
variable "aws_rds_instance_type" {}
variable "aws_rds_storage" {}
variable "aws_rds_multi_az" {}
variable "aws_rds_family" {}

#
# Aurora設定
#
variable "aws_aurora_db_engine_ver" {}
variable "aws_aurora_instance_type" {}
variable "aws_aurora_instance_count" {}
variable "aws_aurora_family" {}

#
# EC2設定
#
variable "aws_ami" {}
variable "aws_ec2_instance_type" {}
variable "aws_ec2_create_flag" {}

#
# ECR設定
#
variable "aws_ecr_repository" {
  type        = string
  description = "Repository name of the container image."
  validation {
    condition     = length(var.aws_ecr_repository) >= 2 && can(regex("^[a-z0-9-_]+$", var.aws_ecr_repository))
    error_message = "0 out of 256 characters maximum (2 minimum). The name must start with a letter and can only contain lowercase letters, numbers, and special characters ._-/."
  }
}

#
# ECS設定
#
variable "app_name" {}
variable "app_profiles_active" {}
variable "app_db_username" {}
variable "app_db_url" {}
variable "app_cpu" {}
variable "app_memory" {}
variable "ecs_desired_count" {}
variable "ecs_health_check_grace_period_seconds" {}
variable "ecs_force_new_deployment" {}
variable "ecs_taskdef_healthcheck" {}
variable "ecs_exec_flag" {}
variable "ecs_readonlyRootFilesystem" {}
variable "ecs_mount_points" {}

#
# ALB設定
#
variable "frontend_app_port" {}
variable "backend_app_port" {}
variable "aws_alb_acm_arn" {}
variable "alb_domain_name" {}
variable "alb_frontend_health_check_path" {}
variable "alb_backend_uri" {}
variable "alb_backend_health_check_path" {}
variable "aws_alb_internal" {}

#
# OIDC設定
#
variable "oidc_flag" {}
variable "frontend_organizations_name" {}
variable "frontend_repository_name" {}
variable "backend_organizations_name" {}
variable "backend_repository_name" {}

#
# cloudfront設定
#
variable "app_domain_name" {}
variable "aws_cf_acm_arn" {}

#
# S3設定
#
variable "aws_s3_bucket_versioning" {}
