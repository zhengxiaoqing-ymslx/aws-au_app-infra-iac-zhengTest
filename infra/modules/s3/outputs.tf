###############################################################################
# System Name : application infra template
# Company     : YMSLJ
# Author      : Hiroki Ishikawa
# Date        : 2024/11/12
# Copyright (c) 2024, YAMAHA MOTOR SOLUTIONS CO., LTD.
#------------------------------------------------------------------------------
# Description
#------------------------------------------------------------------------------
# 
# 定義する内容は、以下の物とする。
# - 変数の共有
#
###############################################################################

output "origin_bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "origin_bucket_id" {
  value = aws_s3_bucket.this.id
}

output "origin_bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "origin_bucket_regional_domain_name" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}

output "origin_bucket_domain_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}