terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      Owner      = var.owner
      Project    = var.project
      Created_by = "Terraform"
    }
  }
}

module "network" {
  source         = "../../modules/network"
  project        = var.project
  owner          = var.owner
  aws_region     = var.aws_region
  aws_profile    = var.aws_profile
  project_domain = var.project_domain
}

module "eks" {
  source             = "../../modules/eks-cluster"
  project            = var.project
  owner              = var.owner
  aws_region         = var.aws_region
  aws_profile        = var.aws_profile
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnets
}

module "aurora-serverless" {
  source             = "../../modules/db/aurora-serverless"
  project            = var.project
  owner              = var.owner
  aws_region         = var.aws_region
  aws_profile        = var.aws_profile
  vpc_id             = module.network.vpc_id
  database_subnet_group_name = module.network.database_subnet_group_name
  app_security_group_id = module.eks.node_security_group_id
  database_version   = "16.9"
  master_username    = "postgres"
  master_password    = "password"
}
