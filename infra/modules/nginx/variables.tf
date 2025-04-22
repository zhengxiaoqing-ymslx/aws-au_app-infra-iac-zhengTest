###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/11/29
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 
# 定義する内容は、以下の物とする。
# - 変数を定義する。
#
###############################################################################

#
# AWS VPC関連の基本情報（VPC ID、Subnet ID等）
#
variable "aws_region_name" {}
variable "aws_subnet_protected-a_id" {}
variable "aws_subnet_protected-c_id" {}

#
# システム名称
#
variable "system_name" {}
variable "environment" {}

#
# ALB設定
#
variable "app_port" {}

#
# ECS設定
#
variable "app_cpu" {}
variable "app_memory" {}
variable "ecs_desired_count" {}
variable "ecs_health_check_grace_period_seconds" {}
variable "ecs_force_new_deployment" {}
variable "aws_account_id" {}
variable "nginx-sg-id" {}
variable "alb_tg_arn" {}
variable "ecs_cluser_id" {}
variable "ecs_exec_flag" {}

#
# S3設定
#
variable "bucket_arn" {}
variable "bucket_id" {}
variable "bucket_regional_domain_name" {}
variable "aws_vpc_s3_endpoint" {}

#
# OIDC設定
#
variable "github_oidc_role_id" {}
