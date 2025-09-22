output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "database_name" {
  value = module.db.cluster_database_name
}

output "database_cluster_endpoint" {
  value = module.db.cluster_endpoint
}

output "vault_installer_role_arn" {
  value = module.secrets-manager.vault_installer_role_arn
}

output "msk_sasl_scram_cmk_arn" {
  value = module.kafka.msk_sasl_scram_cmk_arn
}

output "msk_cluster_arn" {
  value = module.kafka.msk_cluster_arn
}
