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
# - 変数の共有
#
###############################################################################

output "alb-sg-id" {
  value = aws_security_group.alb-sg.id
}

output "ecs-sg-id" {
  value = aws_security_group.ecs-sg.id
}

output "ecs-vpce-sg-id" {
  value = aws_security_group.ecs-vpce-sg.id
}

output "rds-sg-id" {
  value = aws_security_group.rds-sg.id
}

output "ec2-sg-id" {
  value = aws_security_group.ec2-sg.id
}

output "ec2-vpce-sg-id" {
  value = aws_security_group.ec2-vpce-sg.id
}

output "nginx-sg-id" {
  value = one(aws_security_group.nginx-sg[*].id)
}
