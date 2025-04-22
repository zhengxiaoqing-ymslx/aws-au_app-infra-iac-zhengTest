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
# - CloudFrontの設定を定義する。
#
###############################################################################
#
# OAC設定
#
resource "aws_cloudfront_origin_access_control" "this" {
  # albがexternal設定の場合に実行
  count                             = var.create_flag ? 1 : 0
  name                              = lower("oac-${var.environment}-${var.system_name}")
  description                       = "OAC Setting"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Cacheポリシー
data "aws_cloudfront_cache_policy" "CachingOptimized" {
  name = "Managed-CachingOptimized"
}
data "aws_cloudfront_cache_policy" "CachingDisabled" {
  name = "Managed-CachingDisabled"
}

# Origin requestポリシー
data "aws_cloudfront_origin_request_policy" "ManagedAllViewer" {
  name = "Managed-AllViewer"
}

#
# CloudFrontディストリビューション設定
#
resource "aws_cloudfront_distribution" "s3_static_distribution" {
  # albがexternal設定の場合に実行
  count   = var.create_flag ? 1 : 0
  enabled = true
  origin {
    origin_id                = "frontend"
    domain_name              = var.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this[count.index].id
  }
  web_acl_id = aws_wafv2_web_acl.this[count.index].arn
  # NOTE: Origin設定(ALB)
  origin {
    domain_name = var.alb_domain_name
    origin_id   = "backend"
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 60
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  default_root_object = "index.html"

  # domain name
  aliases = ["${var.app_domain_name}","www.${var.app_domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "frontend"

    viewer_protocol_policy = "https-only"
    cache_policy_id  = data.aws_cloudfront_cache_policy.CachingOptimized.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_routing[count.index].arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = var.alb_backend_uri
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["HEAD", "GET", "OPTIONS"]
    target_origin_id = "backend"

    viewer_protocol_policy = "https-only"
    cache_policy_id          = data.aws_cloudfront_cache_policy.CachingDisabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.ManagedAllViewer.id
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = false           # CloudFrontデフォルトの証明書を使用しない
    acm_certificate_arn            = var.aws_acm_arn # us_east_1の証明書をアタッチ
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_function" "spa_routing" {
  # albがexternal設定の場合に実行
  count   = var.create_flag ? 1 : 0
  name    = "spa_routing"
  runtime = "cloudfront-js-2.0"
  comment = "Routing to index"
  publish = true
  code    = file("${path.module}/spa_routing.js")
}

#
# cloudfront WAF設定
#
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_wafv2_web_acl" "this" {
  # albがexternal設定の場合に実行
  count       = var.create_flag ? 1 : 0
  name        = "${var.environment}-${var.system_name}-cf-web-acl"
  description = "Web ACL for ${var.environment}-${var.system_name}-app"
  scope       = "CLOUDFRONT"
  provider    = aws.virginia

  default_action {
    allow {}
  }

  # 無料で使えるManagedRuleを追加
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "TerraformWebACLMetric"
    sampled_requests_enabled   = false
  }
}

#
# S3バケットポリシーの追加設定(WebAccess)
#
resource "aws_s3_bucket_policy" "this" {
  # albがexternal設定の場合に実行
  count  = var.create_flag ? 1 : 0
  bucket = var.bucket_id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowSSLRequestsOnly",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "${var.bucket_arn}",
                "${var.bucket_arn}/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": [
                "${var.bucket_arn}",
                "${var.bucket_arn}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:SourceArn": "${aws_cloudfront_distribution.s3_static_distribution[count.index].arn}"
                }
            }
        }
    ]
}
EOF
}


#
# OIDCロールのポリシー追加設定(deploy)
#
resource "aws_iam_role_policy" "this" {
  # albがexternal設定の場合に実行
  count  = var.create_flag ? 1 : 0
  name   = "${var.environment}-${var.system_name}-app-frontend-policy"
  role   = var.github_oidc_role_id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${var.bucket_arn}",
                "${var.bucket_arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": [
                "${aws_cloudfront_distribution.s3_static_distribution[count.index].arn}"
            ]
        }
    ]
}
EOF
}
