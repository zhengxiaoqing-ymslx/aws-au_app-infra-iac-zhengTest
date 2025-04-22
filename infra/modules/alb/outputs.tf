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
# - 変数の共有
#
###############################################################################

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_frontend_tg_arn" {
  value = one(aws_lb_target_group.frontend[*].arn)
}

output "alb_backend_tg_arn" {
  value = aws_lb_target_group.backend.arn
}
