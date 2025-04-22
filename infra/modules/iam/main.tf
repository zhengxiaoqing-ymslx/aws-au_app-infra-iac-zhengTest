# IDプロバイダを作成
module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
}

# IAMポリシーを作成
resource "aws_iam_policy" "this" {
  name        = "Terraform-OIDC-policy"
  description = "Terraform-OIDC-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "NotAction" : [
          "iam:ListRoles",                      # IAMロールの一覧を取得
          "organizations:DescribeOrganization", # 組織の詳細を取得
          "account:ListRegions"                 # リージョンの一覧を取得
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:DeleteServiceLinkedRole", # サービス連携ロールを削除
          "iam:CreateServiceLinkedRole", # サービス連携ロールを作成
          "iam:DeleteServiceLinkedRole", # サービス連携ロールを削除
          "iam:GetPolicy",               # IAMポリシーの詳細を取得
          "iam:GetOpenIDConnectProvider" # OIDCプロバイダの詳細を取得
        ],
        "Resource" : "arn:aws:iam::${var.account_id}:role/Terraform-OIDC-role"
      }
    ]
  })
}

# IAMロールを作成
resource "aws_iam_role" "this" {
  name = "Terraform-OIDC-role"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.user_name}/${var.repository_name}:*"
          }
        }
      }
    ]
  })
  managed_policy_arns = [aws_iam_policy.this.arn]
}
