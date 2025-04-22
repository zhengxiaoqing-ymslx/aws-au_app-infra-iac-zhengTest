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
# - OIDCの設定を定義する。
#
###############################################################################

# IDプロバイダを作成
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count          = var.oidc_flag ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # ref: https://qiita.com/minamijoyo/items/eac99e4b1ca0926c4310
  # ref: https://zenn.dev/yukin01/articles/github-actions-oidc-provider-terraform
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

# IAMロールを作成
resource "aws_iam_role" "frontend" {
  name = "${var.environment}-${var.system_name}-frontend-OIDC-role"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.frontend_organizations_name}/${var.frontend_repository_name}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "backend" {
  name = "${var.environment}-${var.system_name}-backend-OIDC-role"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.backend_organizations_name}/${var.backend_repository_name}:*"
          }
        }
      }
    ]
  })
}
