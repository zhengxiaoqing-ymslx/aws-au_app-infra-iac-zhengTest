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
variable "aws_region_name" {}
variable "aws_subnet_protected_id" {}

#
# システム名称
#
variable "system_name" {}
variable "environment" {}

#
# EC2設定
#
variable "aws_ami" {}
variable "aws_ec2_instance_type" {}
variable "ec2-sg-id" {}
variable "aws_account_id" {}