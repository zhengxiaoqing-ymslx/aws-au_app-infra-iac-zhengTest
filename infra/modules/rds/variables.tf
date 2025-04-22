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
variable "aws_subnet_private-a_id" {}
variable "aws_subnet_private-c_id" {}
variable "rds-sg-id" {}

#
# システム名称
#
variable "system_name" {}
variable "environment" {}

#
# Database設定
#
variable "db_name" {}
variable "db_username" {}
variable "db_port" {}

#
# RDS設定
#
variable "aws_rds_db_engine_ver" {}
variable "aws_rds_instance_type" {}
variable "aws_rds_storage" {}
variable "aws_rds_multi_az" {}
variable "aws_rds_family" {}