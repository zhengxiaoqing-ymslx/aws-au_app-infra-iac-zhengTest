###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/11/01
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
variable "aws_vpc_id" {}
variable "aws_region_name" {}

#
# システム名称
#
variable "system_name" {}
variable "environment" {}

#
# Database設定
#
variable "db_port" {}

#
# ECS設定
#
variable "frontend_app_port" {}
variable "backend_app_port" {}

variable "create_flag" {} 