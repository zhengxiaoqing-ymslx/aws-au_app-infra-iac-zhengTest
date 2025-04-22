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
# - 静的コンテンツ用S3の設定を定義する。
#
###############################################################################
resource "aws_s3_bucket" "this" {
  bucket = lower("${var.environment}-${var.system_name}-${var.aws_account_id}-static")
}

# index.html設定
#resource "aws_s3_object" "this" {
#  bucket = aws_s3_bucket.this.id
#  key    = "index.html"
#  source = "./index.html"
#}

# バージョニング有効化
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.aws_s3_bucket_versioning
  }
}

# 暗号有効化
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# パブリックアクセスのブロック
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
