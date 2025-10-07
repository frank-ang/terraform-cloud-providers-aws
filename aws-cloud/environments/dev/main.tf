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
  source             = "../../modules/k8s/eks-managed-nodes"
  project            = var.project
  owner              = var.owner
  aws_region         = var.aws_region
  aws_profile        = var.aws_profile
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnets
  route53_private_zone_arn = module.network.aws_route53_private_zone_arn
}
