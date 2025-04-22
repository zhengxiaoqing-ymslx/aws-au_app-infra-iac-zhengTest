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
# - AWS VPC関連の基本情報（リージョン、VPC ID、Subnet ID等）
# - システム名称
#
###############################################################################

provider "aws" {
  region = var.aws_region_name
}

# AWSアカウントIDの取得
data "aws_caller_identity" "current" {}
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

terraform {
  backend "s3" {
    # terraform Ver 1.10.0~
    # To opt-in to S3 native state locking, set use_lockfile to true.
    use_lockfile = true
  }
}

module "sg" {
  source            = "./modules/security_group"
  environment       = var.environment
  system_name       = var.system_name
  frontend_app_port = var.frontend_app_port
  backend_app_port  = var.backend_app_port
  db_port           = var.db_port
  aws_vpc_id        = var.aws_vpc_id
  aws_region_name   = var.aws_region_name
  create_flag       = var.aws_alb_internal
}

module "vpc" {
  source                    = "./modules/vpc"
  environment               = var.environment
  system_name               = var.system_name
  aws_region_name           = var.aws_region_name
  aws_vpc_id                = var.aws_vpc_id
  aws_subnet_protected-a_id = var.aws_subnet_protected-a_id
  aws_subnet_protected-c_id = var.aws_subnet_protected-c_id
  ecs-vpce-sg-id            = module.sg.ecs-vpce-sg-id
  ec2-vpce-sg-id            = module.sg.ec2-vpce-sg-id
}

module "ec2" {
  count                   = var.aws_ec2_create_flag ? 1 : 0
  source                  = "./modules/ec2"
  environment             = var.environment
  system_name             = var.system_name
  aws_account_id          = local.aws_account_id
  aws_region_name         = var.aws_region_name
  aws_subnet_protected_id = var.aws_subnet_protected-a_id
  aws_ami                 = var.aws_ami
  aws_ec2_instance_type   = var.aws_ec2_instance_type
  ec2-sg-id               = module.sg.ec2-sg-id
}

module "rds" {
  count                   = var.db_type == "rds" ? 1 : 0
  source                  = "./modules/rds"
  environment             = var.environment
  system_name             = var.system_name
  db_name                 = var.db_name
  db_username             = var.db_username
  db_port                 = var.db_port
  aws_subnet_private-a_id = var.aws_subnet_private-a_id
  aws_subnet_private-c_id = var.aws_subnet_private-c_id
  aws_rds_db_engine_ver   = var.aws_rds_db_engine_ver
  aws_rds_instance_type   = var.aws_rds_instance_type
  aws_rds_storage         = var.aws_rds_storage
  aws_rds_multi_az        = var.aws_rds_multi_az
  aws_rds_family          = var.aws_rds_family
  rds-sg-id               = module.sg.rds-sg-id
}

module "aurora" {
  count                     = var.db_type == "aurora" ? 1 : 0
  source                    = "./modules/aurora"
  environment               = var.environment
  system_name               = var.system_name
  db_name                   = var.db_name
  db_username               = var.db_username
  db_port                   = var.db_port
  aws_subnet_private-a_id   = var.aws_subnet_private-a_id
  aws_subnet_private-c_id   = var.aws_subnet_private-c_id
  aws_aurora_db_engine_ver  = var.aws_aurora_db_engine_ver
  aws_aurora_instance_type  = var.aws_aurora_instance_type
  aws_aurora_instance_count = var.aws_aurora_instance_count
  aws_aurora_family         = var.aws_aurora_family
  rds-sg-id                 = module.sg.rds-sg-id
}

module "ecr" {
  source             = "./modules/ecr"
  environment        = var.environment
  system_name        = var.system_name
  aws_ecr_repository = var.aws_ecr_repository
}

module "ecs" {
  source                                = "./modules/ecs"
  environment                           = var.environment
  system_name                           = var.system_name
  app_name                              = var.app_name
  app_port                              = var.backend_app_port
  app_profiles_active                   = var.app_profiles_active
  app_db_username                       = var.app_db_username
  app_db_url                            = var.app_db_url
  app_cpu                               = var.app_cpu
  app_memory                            = var.app_memory
  ecs_desired_count                     = var.ecs_desired_count
  ecs_health_check_grace_period_seconds = var.ecs_health_check_grace_period_seconds
  ecs_force_new_deployment              = var.ecs_force_new_deployment
  ecs_taskdef_healthcheck               = var.ecs_taskdef_healthcheck
  ecs_exec_flag                         = var.ecs_exec_flag
  ecs_readonlyRootFilesystem            = var.ecs_readonlyRootFilesystem
  ecs_mount_points                      = var.ecs_mount_points
  aws_account_id                        = local.aws_account_id
  aws_region_name                       = var.aws_region_name
  aws_subnet_protected-a_id             = var.aws_subnet_protected-a_id
  aws_subnet_protected-c_id             = var.aws_subnet_protected-c_id
  repository_url                        = module.ecr.repository_url
  repository_arn                        = module.ecr.repository_arn
  ecs-sg-id                             = module.sg.ecs-sg-id
  alb_tg_arn                            = module.alb.alb_backend_tg_arn
  github_oidc_role_id                   = module.oidc.backend_github_oidc_role_id
}

module "alb" {
  source                         = "./modules/alb"
  environment                    = var.environment
  system_name                    = var.system_name
  aws_vpc_id                     = var.aws_vpc_id
  aws_subnet-a_id                = var.aws_alb_internal == false ? "${var.aws_subnet_public-a_id}" : "${var.aws_subnet_protected-a_id}"
  aws_subnet-c_id                = var.aws_alb_internal == false ? "${var.aws_subnet_public-c_id}" : "${var.aws_subnet_protected-c_id}"
  frontend_app_port              = var.frontend_app_port
  backend_app_port               = var.backend_app_port
  aws_acm_arn                    = var.aws_alb_acm_arn
  aws_alb_internal               = var.aws_alb_internal
  alb_domain_name                = var.alb_domain_name
  alb_frontend_health_check_path = var.alb_frontend_health_check_path
  alb_backend_uri                = var.alb_backend_uri
  alb_backend_health_check_path  = var.alb_backend_health_check_path
  alb-sg-id                      = module.sg.alb-sg-id
}

module "waf" {
  source      = "./modules/waf"
  environment = var.environment
  system_name = var.system_name
  alb_arn     = module.alb.alb_arn
}

module "s3" {
  source                   = "./modules/s3"
  environment              = var.environment
  system_name              = var.system_name
  aws_account_id           = local.aws_account_id
  aws_s3_bucket_versioning = var.aws_s3_bucket_versioning
}

module "cloudfront" {
  create_flag                 = var.aws_alb_internal == false ? true : false
  source                      = "./modules/cloudfront"
  environment                 = var.environment
  system_name                 = var.system_name
  bucket_name                 = module.s3.origin_bucket_name
  bucket_arn                  = module.s3.origin_bucket_arn
  bucket_id                   = module.s3.origin_bucket_id
  bucket_domain_name          = module.s3.origin_bucket_domain_name
  bucket_regional_domain_name = module.s3.origin_bucket_regional_domain_name
  github_oidc_role_id         = module.oidc.frontend_github_oidc_role_id
  alb_domain_name             = var.alb_domain_name
  alb_backend_uri             = var.alb_backend_uri
  app_domain_name             = var.app_domain_name
  aws_acm_arn                 = var.aws_cf_acm_arn
}

module "oidc" {
  source                      = "./modules/oidc"
  oidc_flag                   = var.oidc_flag
  environment                 = var.environment
  system_name                 = var.system_name
  aws_account_id              = local.aws_account_id
  frontend_organizations_name = var.frontend_organizations_name
  frontend_repository_name    = var.frontend_repository_name
  backend_organizations_name  = var.backend_organizations_name
  backend_repository_name     = var.backend_repository_name
}

module "nginx" {
  count                                 = var.aws_alb_internal == true ? 1 : 0
  source                                = "./modules/nginx"
  environment                           = var.environment
  system_name                           = var.system_name
  app_port                              = var.frontend_app_port
  app_cpu                               = 512
  app_memory                            = 1024
  ecs_desired_count                     = var.ecs_desired_count
  ecs_health_check_grace_period_seconds = var.ecs_health_check_grace_period_seconds
  ecs_force_new_deployment              = var.ecs_force_new_deployment
  ecs_cluser_id                         = module.ecs.ecs_cluser_id
  ecs_exec_flag                         = var.ecs_exec_flag
  aws_account_id                        = local.aws_account_id
  aws_region_name                       = var.aws_region_name
  aws_subnet_protected-a_id             = var.aws_subnet_protected-a_id
  aws_subnet_protected-c_id             = var.aws_subnet_protected-c_id
  aws_vpc_s3_endpoint                   = var.aws_vpc_s3_endpoint
  nginx-sg-id                           = module.sg.nginx-sg-id
  alb_tg_arn                            = module.alb.alb_frontend_tg_arn
  bucket_arn                            = module.s3.origin_bucket_arn
  bucket_id                             = module.s3.origin_bucket_id
  bucket_regional_domain_name           = module.s3.origin_bucket_regional_domain_name
  github_oidc_role_id                   = module.oidc.frontend_github_oidc_role_id
}
