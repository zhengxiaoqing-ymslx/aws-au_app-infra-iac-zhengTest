###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/11/01
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 
# 定義する内容は、以下の物とする。
# - RDS for Auroraの設定を定義する。
#
###############################################################################

#
# RDS Subnet Group設定
#
resource "aws_db_subnet_group" "this" {
  name = lower("${var.environment}-${var.system_name}-rds-subnet-group")
  subnet_ids = [
    var.aws_subnet_private-a_id,
    var.aws_subnet_private-c_id,
  ]
  tags = {
    Name = "${var.environment}-${var.system_name}-rds-subnet-group"
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier                  = lower("${var.environment}-${var.system_name}-cluster")
  engine                              = "aurora-postgresql"
  engine_version                      = var.aws_aurora_db_engine_ver
  master_username                     = var.db_username
  manage_master_user_password         = true
  port                                = var.db_port
  database_name                       = var.db_name
  vpc_security_group_ids              = [var.rds-sg-id]
  db_subnet_group_name                = aws_db_subnet_group.this.name
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.this.name
  iam_database_authentication_enabled = false
  storage_encrypted                   = true
  skip_final_snapshot                 = true
  apply_immediately                   = true
}

# パスワードローテーションを７日間から１年間に修正
resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id           = aws_rds_cluster.this.master_user_secret[0].secret_arn
  rotation_rules {
    automatically_after_days = 365
  }
  # 設定値は、初回のみ適用
  lifecycle {
    ignore_changes = [
      rotation_rules
    ]
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  name   = lower("${var.environment}-${var.system_name}-rds-cluster-pg")
  family = var.aws_aurora_family
}

resource "aws_rds_cluster_instance" "this" {
  count = var.aws_aurora_instance_count

  cluster_identifier = aws_rds_cluster.this.id
  identifier         = lower("${var.environment}-${var.system_name}-instance-${count.index}")

  engine                  = aws_rds_cluster.this.engine
  engine_version          = aws_rds_cluster.this.engine_version
  instance_class          = var.aws_aurora_instance_type
  db_subnet_group_name    = aws_db_subnet_group.this.name
  db_parameter_group_name = aws_db_parameter_group.this.name

  monitoring_role_arn = aws_iam_role.aurora_monitoring.arn
  monitoring_interval = 60

  publicly_accessible = true
}

resource "aws_db_parameter_group" "this" {
  name   = lower("${var.environment}-${var.system_name}-rds-db-pg")
  family = var.aws_aurora_family

  parameter {
    apply_method = "pending-reboot"
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pg_hint_plan"
  }
}

resource "aws_iam_role" "aurora_monitoring" {
  name               = "${var.environment}-${var.system_name}-aurora-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.aurora_monitoring_assume.json
}

data "aws_iam_policy_document" "aurora_monitoring_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "monitoring.rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "aurora_monitoring" {
  role       = aws_iam_role.aurora_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
