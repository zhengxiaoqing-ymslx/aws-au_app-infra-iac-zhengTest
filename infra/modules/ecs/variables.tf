###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/11/06
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
variable "repository_url" {}
variable "repository_arn" {}
variable "aws_account_id" {}
variable "ecs-sg-id" {}
variable "alb_tg_arn" {}
variable "github_oidc_role_id" {}
