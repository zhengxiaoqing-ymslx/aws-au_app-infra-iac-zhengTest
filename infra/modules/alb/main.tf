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
# - ECSで使用するALBの設定を定義する。
#
###############################################################################
# count = var.oidc_flag ? 1 : 0

#
# ALB設定
#
resource "aws_lb" "this" {
  name = lower("${var.environment}-${var.system_name}-alb")
  # HTTPレベルでリクエストをハンドリングするALBを使用
  load_balancer_type = "application"
  subnets = [
    var.aws_subnet-a_id,
    var.aws_subnet-c_id
  ]
  internal        = var.aws_alb_internal
  security_groups = [var.alb-sg-id]

  tags = {
    Name = "${var.environment}-${var.system_name}-alb"
  }
}

#
# frontend用のターゲットグループ設定（Local Network公開用）
#
resource "aws_lb_target_group" "frontend" {
  # albのinternal設定の場合に実行
  count       = var.aws_alb_internal ? 1 : 0
  name        = lower("${var.environment}-${var.system_name}-frontend")
  protocol    = "HTTP"
  vpc_id      = var.aws_vpc_id
  target_type = "ip"
  port        = var.frontend_app_port

  health_check {
    path = var.alb_frontend_health_check_path
  }

  tags = {
    Name = "${var.environment}-${var.system_name}-frontend-target-group"
  }
}

#
# backend用のターゲットグループ設定
#
resource "aws_lb_target_group" "backend" {
  name        = lower("${var.environment}-${var.system_name}-backend")
  protocol    = "HTTP"
  vpc_id      = var.aws_vpc_id
  target_type = "ip"
  port        = var.backend_app_port

  health_check {
    path = var.alb_backend_health_check_path
  }

  tags = {
    Name = "${var.environment}-${var.system_name}-backend-target-group"
  }
}

#
# リスナーの設定
#
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  # 証明書の設定
  certificate_arn = var.aws_acm_arn
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # デフォルトアクションの設定
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }

  tags = {
    Name = "${var.environment}-${var.system_name}-alb-listener"
  }
}

#
# frontend用のリスナールールの設定（Local Network公開用）
#
resource "aws_lb_listener_rule" "frontend" {
  # albのinternal設定の場合に実行
  count        = var.aws_alb_internal ? 1 : 0
  listener_arn = aws_lb_listener.this.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  # Todo
  #
  # ドメインチェックは、調査が必要
  #condition {
  #  host_header {
  #    values = ["${var.alb_domain_name}"]
  #  }
  #}
}

#
# backend用のリスナールールの設定
#
resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.this.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["${var.alb_backend_uri}"]
    }
  }

  # Todo
  #
  # ドメインチェックは、調査が必要
  #condition {
  #  host_header {
  #    values = ["${var.alb_domain_name}"]
  #  }
  #}
}
