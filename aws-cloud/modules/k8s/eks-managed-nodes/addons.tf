module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  name = "ebs-csi"
  attach_ebs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node", "kube-system:ebs-csi-controller-sa"]
    }
  }
}
# https://davegallant.ca/blog/amazon-ebs-csi-driver-terraform/
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.49.0-eksbuild.1"
  service_account_role_arn = module.ebs_csi_irsa.arn
  resolve_conflicts_on_update = "OVERWRITE"
}



# https://cert-manager.io/docs/
# nosemgrep: resource-not-on-allowlist
resource "helm_release" "metrics_server" {
  depends_on = [ null_resource.kubectl ]
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}


# https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
resource "aws_eks_addon" "external_dns" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "external-dns"
  addon_version            = "v0.19.0-eksbuild.2"
  service_account_role_arn = module.external_dns_irsa.arn
}

module "external_dns_irsa" {
  # https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  name = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [var.route53_private_zone_arn] # ["arn:aws:route53:::hostedzone/IClearlyMadeThisUp"]
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }
}
