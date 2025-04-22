###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/11/29
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 
# 定義する内容は、以下の物とする。
# - ECSの設定を定義する。
#
###############################################################################

locals {
  app_name = "frontend-nginx"
  ecs_logs  = lower("/ecs/${var.environment}-${var.system_name}-app-fontend")
}

#
# frontend用cloudwatchlog作成
#
resource "aws_cloudwatch_log_group" "this" {
  name              = local.ecs_logs

  tags = {
    Name = "${var.environment}-${var.system_name}-frontend-nginx-log-group"
  }
}

resource "aws_ecr_repository" "this" {
  # リポジトリ名
  # リポジトリ名は、英数字、ハイフン、アンダースコアのみ使用可能
  # 長さは2～256文字
  name = local.app_name

  # タグ
  # タグは、リポジトリを整理したり、検索したりするために使用できる
  tags = {
    # 名前タグ (必須)
    # リポジトリを識別するための名前
    Name = "${var.environment}-${var.system_name}-frontend-nginx-repository"
  }
}

#
# container_definitions設定
#
data "template_file" "this" {
  template = file("${path.module}/taskdef.json.tpl")
  vars = {
    app_name                    = local.app_name
    app_port                    = var.app_port
    repository_url              = "${aws_ecr_repository.this.repository_url}"
    bucket_regional_domain_name = "${var.bucket_regional_domain_name}"
    ecs_logs                    = "${local.ecs_logs}"
    aws_region_name             = "${var.aws_region_name}"
  }
}

# 設定確認用ファイル出力
# resource "local_file" "this" {
#   content  = data.template_file.this.rendered
#   filename = "./frontend_taskdef_check.json"
# }

#
# タスク定義
#
resource "aws_ecs_task_definition" "this" {
  family                   = lower("${var.environment}-${var.system_name}-frontend-nginx-task")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  execution_role_arn       = aws_iam_role.frontend-nginx-task-exec-role.arn
  task_role_arn            = aws_iam_role.frontend-nginx-task-role.arn
  container_definitions    = data.template_file.this.rendered
  ephemeral_storage {
    size_in_gib = 40
  }
  volume {
    name = "NGINX-tmp"
  }
  volume {
    name = "NGINX-confd"
  }
  volume {
    name = "NGINX-amazon-lib"
  }
  volume {
    name = "NGINX-amazon-log"
  }
}

#
# サービス設定
#
resource "aws_ecs_service" "this" {
  name                              = lower("${var.environment}-${var.system_name}-app-frontend")
  cluster                           = var.ecs_cluser_id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.ecs_desired_count
  health_check_grace_period_seconds = var.ecs_health_check_grace_period_seconds
  launch_type                       = "FARGATE"
  force_new_deployment              = var.ecs_force_new_deployment
  enable_execute_command            = var.ecs_exec_flag

  network_configuration {
    security_groups = [var.nginx-sg-id]
    subnets = [
      var.aws_subnet_protected-a_id,
      var.aws_subnet_protected-c_id,
    ]
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = local.app_name
    container_port   = var.app_port
  }

  tags = {
    Name = "${var.environment}-${var.system_name}-app-frontend"
  }
}

##### IAM role
#
# ecs-task-role作成
#
resource "aws_iam_role" "frontend-nginx-task-role" {
  name               = "${var.environment}-${var.system_name}-frontend-nginx-task-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "frontend-nginx-task-policy" {
  name   = "${var.environment}-${var.system_name}-frontend-nginx-task-policy"
  role   = aws_iam_role.frontend-nginx-task-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.aws_region_name}:${var.aws_account_id}:log-group:${local.ecs_logs}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#
# ecs-task-exec-role作成
#
resource "aws_iam_role" "frontend-nginx-task-exec-role" {
  name               = "${var.environment}-${var.system_name}-frontend-nginx-task-exec-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "frontend-nginx-task-exec-role-attach" {
  role       = aws_iam_role.frontend-nginx-task-exec-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#
# S3バケットポリシーの追加設定(NGINX)
#
resource "aws_s3_bucket_policy" "this" {
  # albがexternal設定の場合に実行
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
            "Sid": "Access-to-specific-VPCE-only",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "${var.bucket_arn}/*",
            "Condition": {
                "StringEquals": {
                    "aws:sourceVpce": "${var.aws_vpc_s3_endpoint}"
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
        }
    ]
}
EOF
}
