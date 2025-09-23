terraform {
  required_providers {
    kubectl = {
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
  # "This data source provides information on the IAM source role of an STS assumed role. For non-role ARNs, this data source simply passes the ARN through in issuer_arn."
  arn = data.aws_caller_identity.current.arn
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Path to your kubeconfig file
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

provider "helm" {
    kubernetes = {
        host                   = module.eks.cluster_endpoint
        cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
        exec = {
            api_version = "client.authentication.k8s.io/v1beta1"
            args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
            command     = "aws"
        }
    }
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
  # Try the following to fix MalformedPolicyDocumentException.
  # kms_key_administrators = [data.aws_iam_session_context.current.issuer_arn]
}
