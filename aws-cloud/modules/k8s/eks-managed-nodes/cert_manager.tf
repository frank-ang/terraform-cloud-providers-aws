# https://cert-manager.io/docs/
locals {
  cert_manager_selfsigned_cluster_issuer = "selfsigned-issuer"
}

module "cert_manager_irsa_role" {
  depends_on = [ module.eks ]
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.1"
  name                  = "${var.project}-cert-manager"
  attach_cert_manager_policy = true
  cert_manager_hosted_zone_arns = [var.route53_private_zone_arn]
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [ null_resource.kubectl ]
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true

  set = [
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "serviceAccount.name"
      value = "cert-manager"
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
  depends_on = [helm_release.cert_manager, null_resource.kubectl]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${local.cert_manager_selfsigned_cluster_issuer}
spec:
 selfSigned: {}
YAML
}
