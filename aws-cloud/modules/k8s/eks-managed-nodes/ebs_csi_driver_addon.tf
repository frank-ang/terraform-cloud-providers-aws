# https://davegallant.ca/blog/amazon-ebs-csi-driver-terraform/
# TLS needed for the thumbprint
# provider "tls" {}

#data "tls_certificate" "oidc" {
#  url = module.eks.cluster_oidc_issuer_url #  module.eks.oidc_provider # aws_eks_cluster.main.identity[0].oidc[0].issuer # TODO
#}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.29.1-eksbuild.1" # "v1.49.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
}

#resource "aws_iam_openid_connect_provider" "eks" {
#  url             = module.eks.cluster_oidc_issuer_url # aws_eks_cluster.main.identity.0.oidc.0.issuer
#  client_id_list  = ["sts.amazonaws.com"]
#  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
#}

# IAM
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${module.eks.cluster_oidc_issuer_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.cluster_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

  }
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}