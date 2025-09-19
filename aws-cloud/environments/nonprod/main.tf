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

module "db" {
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
  master_password    = random_password.db_password.result
}


module "secrets-manager" {
  source             = "../../modules/secrets/aws-secrets-manager"
  project            = var.project
  owner              = var.owner
  aws_region         = var.aws_region
  aws_profile        = var.aws_profile
  eks_cluster_name   = module.eks.cluster_name
  database_hostname  = module.db.cluster_endpoint
  database_password  = random_password.db_password.result
}

resource "random_password" "db_password" {
    length           = 8
    min_upper        = 1
    min_lower        = 1
    min_numeric      = 1
}
