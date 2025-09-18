output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "node_iam_role_arn" {
  value = module.eks.node_iam_role_arn
}

#output "oidc_provider" { # DEPRECATED?
#  value = module.eks.oidc_provider
#}

#output "oidc_provider_arn" { # DEPRECATED?
#  value = module.eks.oidc_provider_arn
#}
