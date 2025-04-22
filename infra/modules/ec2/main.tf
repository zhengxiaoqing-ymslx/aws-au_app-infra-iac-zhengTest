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
# - 踏み台EC2の設定を定義する。
#
###############################################################################

# Amazon EC2インスタンスの定義
resource "aws_instance" "bastion_server" {
  ami                    = var.aws_ami
  instance_type          = var.aws_ec2_instance_type
  subnet_id              = var.aws_subnet_protected_id
  iam_instance_profile   = aws_iam_role.this.name
  vpc_security_group_ids = [var.ec2-sg-id]
  user_data              = <<-EOF
                              #!/bin/bash
                              ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
                              userdel -r ec2-user
                              rm -f /etc/sudoers.d/90-cloud-init-users
                              EOF
  tags = {
    Name = "${var.environment}-${var.system_name}-bastion-ec2"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "ssm-log"
  retention_in_days = 90
}

##### IAM role
#
# bastion-ec2-role
#
resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}-${var.system_name}-bastion-ec2-role"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name               = "${var.environment}-${var.system_name}-bastion-ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.environment}-${var.system_name}-bastion-ec2-role-policy"
  role   = aws_iam_role.this.id
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
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": "arn:aws:logs:${var.aws_region_name}:${var.aws_account_id}:log-group:ssm-log:*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "bastion-ec2-role-attach" {
  name       = "bastion-ec2-role-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ssm_document" "document" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<DOC
{
  "schemaVersion": "1.0",
  "description": "Document to hold regional settings for Session Manager",
  "sessionType": "Standard_Stream",
  "inputs": {
    "s3BucketName": "",
    "s3KeyPrefix": "",
    "s3EncryptionEnabled": true,
    "cloudWatchLogGroupName": "ssm-log",
    "cloudWatchEncryptionEnabled": false,
    "idleSessionTimeout": "20",
    "maxSessionDuration": "",
    "cloudWatchStreamingEnabled": true,
    "kmsKeyId": "",
    "runAsEnabled": false,
    "runAsDefaultUser": "",
    "shellProfile": {
      "windows": "",
      "linux": ""
    }
  }
}
DOC
}