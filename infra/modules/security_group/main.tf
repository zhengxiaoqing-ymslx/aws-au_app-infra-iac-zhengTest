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
# - Security Groupの設定を定義する。
#
###############################################################################

#
# S3 prefix listの取得
#
data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region_name}.s3"
}
#output "aws_ec2_managed_prefix_list_s3" {
#    value = data.aws_ec2_managed_prefix_list.s3
#}

#
# Cloudfrot prefix listの取得
#

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
#output "aws_ec2_managed_prefix_list_cloudfront"{
#    value = data.aws_ec2_managed_prefix_list.cloudfront
#}

#
# Application Load Balancer用Security Group (basic-app-alb-sg)
#
resource "aws_security_group" "alb-sg" {
  vpc_id = var.aws_vpc_id
  name   = "${var.environment}-${var.system_name}-alb-sg"
  tags = {
    Name = "${var.environment}-${var.system_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb-sg_allow_https" {
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  security_group_id = aws_security_group.alb-sg.id
  tags = {
    Name = "Internet https"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb-sg_allow_frontend" {
  # albのinternal設定の場合に実行
  count                        = var.create_flag ? 1 : 0
  from_port                    = var.frontend_app_port
  to_port                      = var.frontend_app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.nginx-sg[count.index].id
  security_group_id            = aws_security_group.alb-sg.id
  tags = {
    Name = "ecs frontend connect"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb-sg_allow_backend" {
  from_port                    = var.backend_app_port
  to_port                      = var.backend_app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs-sg.id
  security_group_id            = aws_security_group.alb-sg.id
  tags = {
    Name = "ecs backend connect"
  }
}

#
# ECS用Security Group
#
resource "aws_security_group" "ecs-sg" {
  vpc_id = var.aws_vpc_id
  name   = "${var.environment}-${var.system_name}-ecs-service-sg"
  tags = {
    Name = "${var.environment}-${var.system_name}-ecs-service-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs-sg_allow_backend" {
  from_port                    = var.backend_app_port
  to_port                      = var.backend_app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb-sg.id
  security_group_id            = aws_security_group.ecs-sg.id
  tags = {
    Name = "alb backend connect"
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs-sg_allow_rds" {
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds-sg.id
  security_group_id            = aws_security_group.ecs-sg.id
  tags = {
    Name = "rds connect"
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs-sg_allow_https_task" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs-vpce-sg.id
  security_group_id            = aws_security_group.ecs-sg.id
  tags = {
    Name = "Internet https"
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs-sg_allow_https_s3" {
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3.id
  security_group_id = aws_security_group.ecs-sg.id
  tags = {
    Name = "Internet https"
  }
}

#
# NGINX用Security Group
#
resource "aws_security_group" "nginx-sg" {
  # albのinternal設定の場合に実行
  count  = var.create_flag ? 1 : 0
  vpc_id = var.aws_vpc_id
  name   = "${var.environment}-${var.system_name}-nginx-service-sg"
  tags = {
    Name = "${var.environment}-${var.system_name}-nginx-service-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nginx-sg_allow_frontend" {
  # albのinternal設定の場合に実行
  count                        = var.create_flag ? 1 : 0
  from_port                    = var.frontend_app_port
  to_port                      = var.frontend_app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb-sg.id
  security_group_id            = aws_security_group.nginx-sg[count.index].id
  tags = {
    Name = "alb frontend connect"
  }
}

resource "aws_vpc_security_group_egress_rule" "nginx-sg_allow_https_task" {
  # albのinternal設定の場合に実行
  count                        = var.create_flag ? 1 : 0
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs-vpce-sg.id
  security_group_id            = aws_security_group.nginx-sg[count.index].id
  tags = {
    Name = "Internet https"
  }
}

resource "aws_vpc_security_group_egress_rule" "nginx-sg_allow_https_s3" {
  # albのinternal設定の場合に実行
  count             = var.create_flag ? 1 : 0
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3.id
  security_group_id = aws_security_group.nginx-sg[count.index].id
  tags = {
    Name = "Internet https"
  }
}

#
# ECS TASK VPC Endpoint用Security Group
#
resource "aws_security_group" "ecs-vpce-sg" {
  vpc_id = var.aws_vpc_id
  name   = "${var.environment}-${var.system_name}-ecs-task-vpce-sg"
  tags = {
    Name = "${var.environment}-${var.system_name}-ecs-task-vpce-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs-vpce-sg_allow_https" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs-sg.id
  security_group_id            = aws_security_group.ecs-vpce-sg.id
  tags = {
    Name = "ecs vpce https"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nginx-vpce-sg_allow_https" {
  # albのinternal設定の場合に実行
  count                        = var.create_flag ? 1 : 0
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.nginx-sg[count.index].id
  security_group_id            = aws_security_group.ecs-vpce-sg.id
  tags = {
    Name = "ecs vpce https"
  }
}

#
# RDS用Security Group
#
resource "aws_security_group" "rds-sg" {
  vpc_id = var.aws_vpc_id
  name   = "${var.environment}-${var.system_name}-rds-sg"
  tags = {
    Name = "${var.environment}-${var.system_name}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds-sg_allow_rds_ecs" {
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs-sg.id
  security_group_id            = aws_security_group.rds-sg.id
  tags = {
    Name = "rds connect"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds-sg_allow_rds_ec2" {
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2-sg.id
  security_group_id            = aws_security_group.rds-sg.id
  tags = {
    Name = "rds connect"
  }
}

#
# 踏み台 EC2用Security Group
#
resource "aws_security_group" "ec2-sg" {
  vpc_id = var.aws_vpc_id
  name   = "${var.environment}-${var.system_name}-bastion-ec2-sg"
  tags = {
    Name = "${var.environment}-${var.system_name}-bastion-ec2-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "ec2-sg_allow_rds" {
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds-sg.id
  security_group_id            = aws_security_group.ec2-sg.id
  tags = {
    Name = "rds connect"
  }
}

resource "aws_vpc_security_group_egress_rule" "ec2-sg_allow_https" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2-vpce-sg.id
  security_group_id            = aws_security_group.ec2-sg.id
  tags = {
    Name = "ec2 vpce https"
  }
}

#resource "aws_vpc_security_group_egress_rule" "ec2-sg_allow_https_s3" {
#  from_port                    = 443
#  to_port                      = 443
#  ip_protocol                  = "tcp"
#  prefix_list_id               = data.aws_ec2_managed_prefix_list.s3.id
#  security_group_id            = aws_security_group.ec2-sg.id
#  tags = {
#    Name = "Internet https"
#  }
#}

#
# 踏み台 EC2 VPC Endpoint用Security Group
#
resource "aws_security_group" "ec2-vpce-sg" {
  vpc_id = var.aws_vpc_id
  name   = "${var.environment}-${var.system_name}-bastion-ec2-vpce-sg"
  tags = {
    Name = "${var.environment}-${var.system_name}-bastion-ec2-vpce-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2-vpce-sg_allow_https" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2-sg.id
  security_group_id            = aws_security_group.ec2-vpce-sg.id
  tags = {
    Name = "ec2 vpce https"
  }
}
