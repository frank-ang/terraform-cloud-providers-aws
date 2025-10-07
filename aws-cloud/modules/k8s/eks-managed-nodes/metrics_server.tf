# https://cert-manager.io/docs/
# nosemgrep: resource-not-on-allowlist
resource "helm_release" "metrics_server" {
  depends_on = [ null_resource.kubectl ]
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}
