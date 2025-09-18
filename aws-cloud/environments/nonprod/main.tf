terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

