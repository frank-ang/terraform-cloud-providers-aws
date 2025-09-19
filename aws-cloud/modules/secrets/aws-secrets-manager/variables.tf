variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "project" {
  type = string
}

variable "owner" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "database_hostname" {
  type = string
}

variable "database_password" {
  type = string
}

variable "vault_installer_namespace" {
  type = string
  default = "foo"
}

variable "vault_installer_serviceaccount" {
  type = string
  default = "bar"
}

variable "tm_iam_prefix" {
  type = string
  default = "foobar"
}

variable "secret_prefix" {
  type = string
  default = "foobar"
}
