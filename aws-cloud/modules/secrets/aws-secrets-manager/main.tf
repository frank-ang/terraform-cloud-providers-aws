data "aws_eks_cluster" "eks" {
    depends_on = [var.eks_cluster_name]
    name       = var.eks_cluster_name
}

data "aws_caller_identity" "main" {}

locals {
    db_secrets_name  = "root-db-secrets"
    db_secrets_value = {
        "${var.database_hostname}" = var.database_password
    }
    aws_account_id = data.aws_caller_identity.main.account_id
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
  name                    = "${var.secret_manager_prefix}/${local.db_secrets_name}"
  description             = "TM database root credentials for ${var.database_hostname}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "root_db_secret" {
  secret_id     = aws_secretsmanager_secret.root_db_secret.id
  secret_string = jsonencode(local.db_secrets_value)
}


#module "aws_sm_vault_installer" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "5.37.0"
#  role_name = "${var.project}-vault-installer"
#  role_policy_arns = {
#    "min_access" = aws_iam_policy.aws_sm_vault_installer_permission_boundary.arn
#  }
#  role_permissions_boundary_arn = aws_iam_policy.aws_sm_vault_installer_permission_boundary.arn
#  oidc_providers = {
#    main = {
#      provider_arn               = "TODO local.eks_oidc_provider_arn"
#      namespace_service_accounts = ["${var.vault_installer_namespace}:${var.vault_installer_serviceaccount}"]
#    }
#  }
#}

resource "aws_iam_policy" "aws_sm_vault_installer_permission_boundary" {
  name   = "${var.project}-vault-installer-permission-boundary"
  policy = data.aws_iam_policy_document.aws_sm_vault_installer_permission_boundary.json
}

data "aws_iam_policy_document" "aws_sm_vault_installer_permission_boundary" {
  statement {
    sid    = "AllowRolesOnlyInPath"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
    ]
    resources = [
      "arn:aws:iam::${local.aws_account_id}:role/${var.tm_iam_prefix}/*"
    ]
  }
  statement {
    sid    = "AllowSecretsOnlyInPath"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:UpdateSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${local.aws_account_id}:secret:${var.secret_manager_prefix}/*",
    ]
  }
}
