
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "aws_route53_private_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "project_domain" {
  value = var.project_domain
}