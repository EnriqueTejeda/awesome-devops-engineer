# CONFIG AWS
region = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
# CONFIG LABEL
namespace = "example"
stage = "prod"
name = "eks"
tags = {
    "Name" = "example-prod-eks-cluster"
    "Stage" = "prod"
    "Namespace" = "example"
    "Application" = "eks-example"
    "Version" = "0.1.0"
}

# Tags for auto-search VPC
data_vpc_tags = {
    "Name" = "eks-vpc"
    "Stage" = "prod"
    "Namespace" = "example"
    "Application" = "eks-example"
    "Version" = "0.1.0"
}

# Node Group Configuration
instance_types = ["t3.medium"]
max_size = 3
min_size = 1
desired_size = 1
disk_size = 50

# IAM Policy
iam_group_policy_eks = "DevOps-Training"

# Kubectl Configure & Kubernetes Version
kubernetes_version = "1.18" # Q4 2020
kubernetes_labels = {}
apply_config_map_aws_auth = true
enable_cluster_autoscaler = true
oidc_provider_enabled = true
enabled_cluster_log_types = []
cluster_log_retention_period = 0
