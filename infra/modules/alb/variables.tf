###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/11/06
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
variable "aws_vpc_id" {}
variable "aws_subnet-a_id" {}
variable "aws_subnet-c_id" {}

#
# システム名称
#
variable "system_name" {}
variable "environment" {}

#
# ALB設定
#
variable "frontend_app_port" {}
variable "backend_app_port" {}
variable "aws_acm_arn" {}
variable "aws_alb_internal" {}
variable "alb_domain_name" {}
variable "alb_frontend_health_check_path" {}
variable "alb_backend_uri" {}
variable "alb_backend_health_check_path" {}
variable "alb-sg-id" {}
