terraform {
  required_providers {
    kubectl = { # TODO UNUSED.
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

locals {
  eks_name           = "${var.project}-eks"
  kubernetes_version = "1.33"
  aws_account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}

provider "kubernetes" {
    config_path = "~/.kube/config"
}

provider "kubectl" { # TODO UNUSED.
  config_path = "~/.kube/config" 
}

provider "helm" {
    kubernetes = {
      config_path = "~/.kube/config"
    }
}

resource "null_resource" "kubectl" { # TODO rename to kubectx
    provisioner "local-exec" {
        command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${data.aws_eks_cluster.eks.name}"
    }
    depends_on = [ module.eks ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.3"

  name               = local.eks_name
  kubernetes_version = local.kubernetes_version

  # Optional
  endpoint_public_access  = true
  endpoint_private_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Cluster Secrets
  # Disable encryption, to workaround KMS MalformedPolicyDocumentException: The new key policy will not allow you to update the key policy in the future.
  encryption_config = null
  create_kms_key = false
}
