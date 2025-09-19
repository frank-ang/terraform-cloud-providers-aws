# AWS Cloud Platform for Thought Machine Vault Core

## Create Infrastructure

### Configure

Execute in the `environments/[env]` directory.
Configure `terraform.tfvars`.

### Deploy

```sh
terraform init
terraform plan
terraform apply
```

### Verify

#### Verify EKS Cluster
Configure kubectl
```sh
source terraform.tfvars
eks_cluster_name=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --region "$aws_region" --profile "$aws_profile" --name "$eks_cluster_name"
```

Deploy sample "inflate" deployment
```sh
cd ../../modules/eks-cluster
kubectl get nodes
kubectl apply -f example-deployment.yaml
kubectl rollout status deployment/inflate
kubectl describe deployment/inflate
kubectl delete -f example-deployment.yaml
kubectl get nodes
cd -
```

## Destroy Infrastructure

### Destroy AWS Resources

```sh
terraform destroy
```
