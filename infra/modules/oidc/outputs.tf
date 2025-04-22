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
# - 変数の共有
#
###############################################################################

output "frontend_github_oidc_role_id" {
  value = aws_iam_role.frontend.id
}

output "frontend_github_oidc_role_arn" {
  value = aws_iam_role.frontend.arn
}

output "backend_github_oidc_role_id" {
  value = aws_iam_role.backend.id
}

output "backend_github_oidc_role_arn" {
  value = aws_iam_role.backend.arn
}
