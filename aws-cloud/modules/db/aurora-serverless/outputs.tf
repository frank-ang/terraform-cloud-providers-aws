output "cluster_database_name" {
  value = module.aurora_postgresql_v2.cluster_database_name
}

output "cluster_endpoint" {
  value = module.aurora_postgresql_v2.cluster_endpoint
}

output "security_group_id" {
  value = module.aurora_postgresql_v2.security_group_id
}
