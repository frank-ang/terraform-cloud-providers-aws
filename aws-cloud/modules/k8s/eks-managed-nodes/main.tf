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

resource "null_resource" "kubectl" {
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
  create_iam_role = true

  # Optional
  endpoint_public_access  = true
  endpoint_private_access = true
  # cluster networking
  vpc_id                               = var.vpc_id
  control_plane_subnet_ids             = var.private_subnet_ids
  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # observability
  create_cloudwatch_log_group = false
  enabled_log_types   = []

  # addons
  addons = {
    coredns = {}
    #eks-pod-identity-agent = {
    #  before_compute = true
    #}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true # Ensures CNI is configured before nodes join
      service_account_role_arn = module.vpc_cni_irsa.arn
    }
    #aws-ebs-csi-driver = {
    #  most_recent = true
    #  service_account_role_arn = module.ebs_csi_irsa.arn
    #  # resolve_conflicts_on_create = "OVERWRITE"
    #}
  }

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  #compute_config = {
  #  enabled    = true
  #  node_pools = ["general-purpose"]
  #}

  subnet_ids = var.private_subnet_ids

  # Cluster Secrets
  # Disable encryption, to workaround KMS MalformedPolicyDocumentException: The new key policy will not allow you to update the key policy in the future.
  encryption_config = null
  create_kms_key = false

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.project
  }

  eks_managed_node_groups = {
    "${var.project}-on" = {
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      instance_types = ["m6a.2xlarge", "m5a.2xlarge", "m5.2xlarge", "c6a.2xlarge", "c5a.2xlarge", "c5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      labels = {
        # Karpenter to run on nodes not managed by itself.
        "karpenter.sh/controller" = "true"
      }
      # iam_role_additional_policies = { AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" }
    }
  }
}
