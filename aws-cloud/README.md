# AWS Cloud Platform for Thought Machine Vault Core

Terraform templates to provision AWS Cloud infrastructure prerequisites necessary for deployment of the Thought Machine Vault Core banking platform. A prescriptive infrastructure is 

## Architecture Overview

Environments are configured in the [environments](./environments) directory. Currently, a nonprod environment is provided.

Each environment depends on a selection of supporting component Terraform modules in the [modules](./modules) directory.

The project structure is based on guidelines in [Terraform Best Practices for Large-size infrastructure with Terraform](https://www.terraform-best-practices.com/examples/terraform/large-size-infrastructure-with-terraform)

## Project Structure

```
aws-cloud/
├── modules/                    # Reusable Terraform modules
│   ├──db/                      # Modules for databases
│   ├──k8s/                     # Modules for Kubernetes clusters
│   ├──kafka/                   # Modules for Kafka clusters
│   ├──network/                 # Module for networking
│   ├──secrets/                 # Modules for secrets management
├── environments/               # Environment-specific configurations
│   ├── nonprod/                # Non-production environment
└── README.md                   # This file
```

## Features

### Database
* Amazon Aurora Serverless for PostgreSQL instance.

### Kubernetes Cluster
* Amazon EKS Auto Mode cluster.

### Kafka Cluster
* Amazon MSK cluster with 3 brokers.

### Network
* VPC network. Subnets across 3 Availability Zones, and DNS Route53 private zone.

### Secrets
* AWS Secrets Manager, with database root secret, and installs secrets-store CSI driver helm chart.

## Quick Start

### Configure

Configure `terraform.tfvars` in the selected `[environments](./environments)/ENV_NAME` subdirectory.

### Deploy Infrastucture

```sh
terraform init
terraform plan
terraform apply
```

### Verify

Configure `kubectl` and verify connectivity to Kubernetes cluster.
```sh
source terraform.tfvars
eks_cluster_name=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --region "$aws_region" --profile "$aws_profile" --name "$eks_cluster_name"
```

### Destroy Infrastructure

```sh
terraform destroy
```
