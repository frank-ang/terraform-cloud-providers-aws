output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "database_name" {
  value = module.aurora-serverless.cluster_database_name
}

output "database_cluster_endpoint" {
  value = module.aurora-serverless.cluster_endpoint
}