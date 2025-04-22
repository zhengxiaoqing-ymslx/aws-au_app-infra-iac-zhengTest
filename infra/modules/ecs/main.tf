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
# - ECSの設定を定義する。
#
###############################################################################

locals {
  my_secrets = {
    APP_PROFILES_ACTIVE = var.app_profiles_active
    DB_URL              = var.app_db_url
    DB_USERNAME         = var.app_db_username
    DB_PASSWORD         = ""
  }
  ecs_logs = lower("/ecs/${var.environment}-${var.system_name}-app-backend")
}

resource "random_id" "account" {
  byte_length = 4
}

#
# backend用cloudwatchlog作成
#
resource "aws_cloudwatch_log_group" "this" {
  name              = local.ecs_logs

  tags = {
    Name = "${var.environment}-${var.system_name}-app-backend-log-group"
  }
}

#
# シークレット設定
#
resource "aws_secretsmanager_secret" "this" {
  name = lower("${var.environment}-${var.system_name}-app-ecs-task-env-secret-${random_id.account.hex}")
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(local.my_secrets)

  # 設定値は、初回のみ適用
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

#
# container_definitions設定
#
data "template_file" "this" {
  template = file("${path.module}/taskdef.json.tpl")
  vars = {
    app_name               = "${var.app_name}"
    app_port               = var.app_port
    app_profiles_active    = "${aws_secretsmanager_secret_version.this.arn}:APP_PROFILES_ACTIVE::"
    db_url                 = "${aws_secretsmanager_secret_version.this.arn}:DB_URL::"
    db_username            = "${aws_secretsmanager_secret_version.this.arn}:DB_USERNAME::"
    db_password            = "${aws_secretsmanager_secret_version.this.arn}:DB_PASSWORD::"
    repository_url         = "${var.repository_url}"
    ecs_logs               = "${local.ecs_logs}"
    healthcheck_command    = "${var.ecs_taskdef_healthcheck[0]}"
    healthcheck_param      = "${var.ecs_taskdef_healthcheck[1]}"
    readonlyRootFilesystem = var.ecs_readonlyRootFilesystem
    mount_points           = var.ecs_mount_points
    aws_region_name        = "${var.aws_region_name}"
  }
}

# 設定確認用ファイル出力
# resource "local_file" "this" {
#   content  = data.template_file.this.rendered
#   filename = "./backend_taskdef_check.json"
# }

#
# クラスター設定
#
resource "aws_ecs_cluster" "this" {
  name = lower("${var.environment}-${var.system_name}-app-ecs-cluster")

  tags = {
    Name = "${var.environment}-${var.system_name}-app-ecs-cluster"
  }
}

#
# タスク定義
#
resource "aws_ecs_task_definition" "this" {
  family                   = lower("${var.environment}-${var.system_name}-app-ecs-task")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  execution_role_arn       = aws_iam_role.ecs-task-exec-role.arn
  task_role_arn            = aws_iam_role.ecs-task-role.arn
  container_definitions    = data.template_file.this.rendered
  ephemeral_storage {
    size_in_gib = 40
  }
  volume {
    name = "YNA-G3-logs"
  }
  volume {
    name = "YNA-G3-tmp"
  }
  volume {
    name = "YNA-G3-amazon-lib"
  }
  volume {
    name = "YNA-G3-amazon-log"
  }
}

#
# サービス設定
#
resource "aws_ecs_service" "this" {
  name                              = lower("${var.environment}-${var.system_name}-app-backend")
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.ecs_desired_count
  health_check_grace_period_seconds = var.ecs_health_check_grace_period_seconds
  launch_type                       = "FARGATE"
  force_new_deployment              = var.ecs_force_new_deployment
  enable_execute_command            = var.ecs_exec_flag

  network_configuration {
    security_groups = [var.ecs-sg-id]
    subnets = [
      var.aws_subnet_protected-a_id,
      var.aws_subnet_protected-c_id,
    ]
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = var.app_name
    container_port   = var.app_port
  }

  tags = {
    Name = "${var.environment}-${var.system_name}-app-backend"
  }

}

##### IAM role
#
# ecs-task-role作成
#
resource "aws_iam_role" "ecs-task-role" {
  name               = "${var.environment}-${var.system_name}-app-ecs-task-role"
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

resource "aws_iam_role_policy" "ecs-task-policy" {
  name   = "${var.environment}-${var.system_name}-app-ecs-task-policy"
  role   = aws_iam_role.ecs-task-role.id
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
resource "aws_iam_role" "ecs-task-exec-role" {
  name               = "${var.environment}-${var.system_name}-app-ecs-task-exec-role"
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

resource "aws_iam_role_policy" "ecs-task-exec-policy" {
  name   = "${var.environment}-${var.system_name}-app-ecs-task-exec-policy"
  role   = aws_iam_role.ecs-task-exec-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "${aws_secretsmanager_secret.this.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-exec-role-attach" {
  role       = aws_iam_role.ecs-task-exec-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#
# OIDCロールのポリシー追加設定(deploy)
#
resource "aws_iam_role_policy" "this" {
  name   = "${var.environment}-${var.system_name}-app-backend-policy"
  role   = var.github_oidc_role_id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CompleteLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage"
            ],
            "Resource": [
                "${var.repository_arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:UpdateService"
            ],
            "Resource": [
                "${aws_ecs_service.this.id}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeTasks",
                "ecs:ListTasks"
            ],
            "Resource": "*",
            "Condition": {
                "ArnEquals": {
                    "ecs:cluster": "${aws_ecs_cluster.this.arn}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": [
                "${aws_iam_role.ecs-task-role.arn}",
                "${aws_iam_role.ecs-task-exec-role.arn}"
            ],
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}
