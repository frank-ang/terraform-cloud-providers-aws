# https://cert-manager.io/docs/
locals {
  cert_manager_chart_name      = "cert-manager"
  cert_manager_namespace       = local.cert_manager_chart_name
  cert_manager_service_account = local.cert_manager_chart_name
  cert_manager_selfsigned_cluster_issuer = "selfsigned-issuer"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = local.cert_manager_namespace
  }
}

module "cert_manager_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.1"
  name                  = "${var.project}-cert-manager"
  attach_cert_manager_policy = true
  cert_manager_hosted_zone_arns = [var.route53_private_zone_arn]
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn # local.eks_oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.cert_manager.id}:${local.cert_manager_service_account}"]
    }
  }
}

# nosemgrep: resource-not-on-allowlist
resource "helm_release" "cert_manager" {
  name       = local.cert_manager_chart_name
  repository = "https://charts.jetstack.io"
  chart      = local.cert_manager_chart_name
  namespace  = kubernetes_namespace.cert_manager.id
  set = [
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "serviceAccount.name"
      value = local.cert_manager_service_account
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.cert_manager_irsa_role.arn
    },
    {
      name  = "installCRDs"
      value = true
    },
    # to solve this error: "propagation check failed" err="NS ns-1024.awsdns-00.org.:53 returned REFUSED
    # certificate was not ready
    # https://github.com/cert-manager/cert-manager/issues/1627
    {
      name  = "dns01RecursiveNameserversOnly"
      value = true
    },
    {
      name  = "dns01RecursiveNameservers"
      value = "8.8.8.8:53"
    }
  ]
}

resource "kubectl_manifest" "cert_manager_cluster_issuer_selfsigned" {
  depends_on = [helm_release.cert_manager]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${local.cert_manager_selfsigned_cluster_issuer}
spec:
  selfSigned: {}
YAML
}