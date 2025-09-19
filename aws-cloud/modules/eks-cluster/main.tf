locals {
  eks_name           = "${var.project}-eks"
  kubernetes_version = "1.33"
}

data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  # "This data source provides information on the IAM source role of an STS assumed role. For non-role ARNs, this data source simply passes the ARN through in issuer_arn."
  arn = data.aws_caller_identity.current.arn
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
