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
# システム名称
#
variable "system_name" {}
variable "environment" {}

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
