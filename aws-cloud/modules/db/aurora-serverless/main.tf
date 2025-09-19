locals {
  rds_name = "${var.project}-rds"
}

module "aurora_postgresql_v2" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name              = local.rds_name
  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  engine_version    = var.database_version
  storage_encrypted = true
  master_username   = var.master_username

  vpc_id               = var.vpc_id
  db_subnet_group_name = var.database_subnet_group_name
  security_group_rules = {
    app_security_group_ingress = {
      source_security_group_id = var.app_security_group_id
    }
  }

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  enable_http_endpoint = true

  serverlessv2_scaling_configuration = {
    min_capacity             = 0
    max_capacity             = 10
    seconds_until_auto_pause = 3600
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
    # two = {}
  }

  cluster_performance_insights_enabled = true
}
