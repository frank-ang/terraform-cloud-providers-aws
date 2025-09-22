
output "root_db_secret_arn" {
  value = aws_secretsmanager_secret.root_db_secret.arn
}
