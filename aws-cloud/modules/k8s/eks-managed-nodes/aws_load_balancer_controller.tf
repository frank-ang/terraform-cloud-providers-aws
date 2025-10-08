#locals {
#  aws_load_balancer_controller_chart_name      = "aws-load-balancer-controller"
#  aws_load_balancer_controller_service_account = local.aws_load_balancer_controller_chart_name
#  # aws_load_balancer_controller_namespace       = "kube-system"
#}

module "aws_load_balancer_controller_irsa_role" {
  # https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  # version = "5.60.0"
  name                              = "aws-load-balancer-controller" # "${module.eks.cluster_name}-loadbalancer"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# nosemgrep: resource-not-on-allowlist
resource "helm_release" "aws_load_balancer_controller" {
  # https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.4"
  namespace  = "kube-system"
  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = true # false # true
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller" # local.aws_load_balancer_controller_service_account
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.aws_load_balancer_controller_irsa_role.arn
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    }
  ]
  depends_on = [
    module.aws_load_balancer_controller_irsa_role
  ]
}
