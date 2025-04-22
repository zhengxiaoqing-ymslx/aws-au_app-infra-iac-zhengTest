###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/11/15
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
# システム名称
#
variable "system_name" {}
variable "environment" {}

variable "aws_account_id" {}
variable "frontend_organizations_name" {}
variable "frontend_repository_name" {}
variable "backend_organizations_name" {}
variable "backend_repository_name" {}
variable "oidc_flag" {}