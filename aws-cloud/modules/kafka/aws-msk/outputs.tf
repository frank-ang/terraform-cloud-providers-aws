output cluster_name {
    value = aws_msk_cluster.main.cluster_name
}

output "msk_sasl_scram_cmk_arn" {
  value = aws_kms_key.msk_sasl_scram.arn
}
