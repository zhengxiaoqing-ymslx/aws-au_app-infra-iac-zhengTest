###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hideki Itou
# Date        : 2024/10/30
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 
# 定義する内容は、以下の物とする。
# - VPC Endpointの設定を定義する。
#
###############################################################################

resource "aws_vpc_endpoint" "interface_ecs" {
  for_each = toset(var.vpc_endpoint_ecs)

  vpc_id              = var.aws_vpc_id
  service_name        = "com.amazonaws.${var.aws_region_name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    var.aws_subnet_protected-a_id,
    var.aws_subnet_protected-c_id,
  ]
  security_group_ids = [
    var.ecs-vpce-sg-id,
  ]
  tags = {
    Name = "${var.environment}-${var.system_name}-${each.value}-endpoint"
  }
}

resource "aws_vpc_endpoint" "interface_common" {
  for_each = toset(var.vpc_endpoint_common)

  vpc_id              = var.aws_vpc_id
  service_name        = "com.amazonaws.${var.aws_region_name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    var.aws_subnet_protected-a_id,
    var.aws_subnet_protected-c_id,
  ]
  security_group_ids = [
    var.ecs-vpce-sg-id,
    var.ec2-vpce-sg-id,
  ]
  tags = {
    Name = "${var.environment}-${var.system_name}-${each.value}-endpoint"
  }
}

resource "aws_vpc_endpoint" "interface_ec2" {
  vpc_id              = var.aws_vpc_id
  service_name        = "com.amazonaws.${var.aws_region_name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    var.aws_subnet_protected-a_id,
    var.aws_subnet_protected-c_id,
  ]
  security_group_ids = [
    var.ec2-vpce-sg-id,
  ]
  tags = {
    Name = "${var.environment}-${var.system_name}-ec2messages-endpoint"
  }
}