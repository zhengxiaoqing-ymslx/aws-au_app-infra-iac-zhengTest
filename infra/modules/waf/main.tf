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
# - ALBで使用するWAFの設定を定義する。
#
###############################################################################

resource "aws_wafv2_web_acl" "this" {
  name        = "${var.environment}-${var.system_name}-web-acl"
  description = "Example of a managed rule by terraform."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "core-rule-set"
    priority = 101

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "core-rule-set-rule-metric"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "${var.environment}-${var.system_name}-waf"
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.environment}-${var.system_name}-web-acl-metric"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}