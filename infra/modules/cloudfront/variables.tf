###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hiroki Ishikawa
# Date        : 2024/11/12
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 
# 定義する内容は、以下の物とする。
# - 変数を定義する。
#
###############################################################################

variable "system_name" {}
variable "environment" {}
variable "bucket_arn" {}
variable "bucket_name" {}
variable "bucket_id" {}
variable "bucket_domain_name" {}
variable "bucket_regional_domain_name" {}
variable "github_oidc_role_id" {}


#
# cloudfront設定
#
variable "alb_domain_name" {}
variable "alb_backend_uri" {}
variable "app_domain_name" {}
variable "aws_acm_arn" {}
variable "create_flag" {} 