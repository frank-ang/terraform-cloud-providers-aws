#helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
#helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver
#helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
#helm install -n kube-system secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws

data "aws_eks_cluster" "eks" {
    name = var.eks_cluster_name
}

locals {
    db_secrets_name  = "root-db-secrets"
    db_secrets_value = {
        "${var.database_hostname}" = var.database_password
    }
}

provider "helm" {
    kubernetes = {
        host                   = data.aws_eks_cluster.eks.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
        exec = {
            api_version = "client.authentication.k8s.io/v1beta1"
            args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks.name]
            command     = "aws"
        }
    }
}

# nosemgrep: resource-not-on-allowlist
resource "helm_release" "secrets-provider-aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
}

# database root password
resource "aws_secretsmanager_secret" "root_db_secret" {
  name                    = "${var.tm_iam_prefix}/${var.secret_prefix}/${local.db_secrets_name}"
  description             = "TM database root credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "root_db_secret" {
  secret_id     = aws_secretsmanager_secret.root_db_secret.id
  secret_string = jsonencode(local.db_secrets_value)
}
