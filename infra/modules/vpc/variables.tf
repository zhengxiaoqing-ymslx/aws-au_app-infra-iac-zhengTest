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
variable "aws_subnet_protected-a_id" {}
variable "aws_subnet_protected-c_id" {}
variable "ecs-vpce-sg-id" {}
variable "ec2-vpce-sg-id" {}

# VPC Endpoint for ecs
variable "vpc_endpoint_ecs" {
  type    = list(any)
  default = ["ecr.api", "ecr.dkr", "secretsmanager"]
}

# VPC Endpoint for common
variable "vpc_endpoint_common" {
  type    = list(any)
  default = ["logs", "ssm", "ssmmessages"]
}

#
# システム名称
#
variable "system_name" {}
variable "environment" {}
