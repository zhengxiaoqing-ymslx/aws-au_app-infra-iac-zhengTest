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
# - RDS for PostgreSQLの設定を定義する。
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

resource "aws_db_instance" "this" {
  identifier                            = lower("${var.environment}-${var.system_name}-rds")
  db_name                               = var.db_name
  allocated_storage                     = var.aws_rds_storage
  storage_type                          = "gp3"
  engine                                = "postgres"
  engine_version                        = var.aws_rds_db_engine_ver
  instance_class                        = var.aws_rds_instance_type
  db_subnet_group_name                  = aws_db_subnet_group.this.name
  username                              = var.db_username
  manage_master_user_password           = true
  port                                  = var.db_port
  backup_retention_period               = 0
  multi_az                              = var.aws_rds_multi_az
  skip_final_snapshot                   = true
  vpc_security_group_ids                = [var.rds-sg-id]
  parameter_group_name                  = aws_db_parameter_group.this.name
  storage_encrypted                     = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  auto_minor_version_upgrade            = false
  maintenance_window                    = "Sat:20:00-Sat:21:00"
  deletion_protection                   = false
  apply_immediately                     = false

  tags = {
    Name = "${var.environment}-${var.system_name}-rds"
  }
}

output "aws_rds_param" {
  value = aws_db_instance.this
}

# パスワードローテーションを７日間から１年間に修正
resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id           = aws_db_instance.this.master_user_secret[0].secret_arn
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

resource "aws_db_parameter_group" "this" {
  name   = lower("${var.environment}-${var.system_name}-rds-db-pg")
  family = var.aws_rds_family

  parameter {
    apply_method = "pending-reboot"
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pg_hint_plan"
  }
}

data "aws_iam_policy" "rds_monitoring_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_monitoring_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring_role" {
  name               = "rds-enhanced-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_role.json
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_role" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = data.aws_iam_policy.rds_monitoring_role.arn
}
