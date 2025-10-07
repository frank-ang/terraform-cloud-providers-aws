# https://kubernetes.github.io/ingress-nginx/deploy/
locals {
  ingress_nginx_chart_name = "ingress-nginx"
  ingress_nginx_namespace  = local.ingress_nginx_chart_name
  ingress_nginx_ingress_class = "ingress-nginx-private"
}

# nosemgrep: resource-not-on-allowlist
resource "helm_release" "ingress_nginx" {
  count = 0  # TEMP DISABLE bypass helm deploy failures
  depends_on = [ null_resource.kubectl ]
  name       = local.ingress_nginx_chart_name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = local.ingress_nginx_chart_name
  namespace  = local.ingress_nginx_namespace # kubernetes_namespace.ingress_nginx.id
  create_namespace = true
  # ingress-nginx helm values
  # https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml
  set = [
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/service/annotations/#traffic-routing
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "external"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
      value = "ip"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internal"
    },
    {
      # To allow ingress controller to see clients source IPs in order to do IP whitelisting
      name  = "controller.service.externalTrafficPolicy"
      value = "Local"
    },
    {
      name = "controller.ingressClass"
      # value = each.value.nginx_ingress_class_name
      value = local.ingress_nginx_ingress_class
    },
    {
      name  = "controller.ingressClassResource.controllerValue"
      value = "k8s.io/${local.ingress_nginx_ingress_class}"
    },
    {
      name  = "controller.ingressClassResource.name"
      value = local.ingress_nginx_ingress_class
    },
    {
      # Process Ingress objects without ingressClass annotation/ingressClassName field Overrides value for --watch-ingress-without-class flag of the controller binary
      name  = "controller.watchIngressWithoutClass"
      value = "false"
    },
    {
      # We enable ssl passthrough for strimzi kafka
      name  = "controller.extraArgs.enable-ssl-passthrough"
      value = "true"
    },
  ]
}


