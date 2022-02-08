# CONFIG AWS
region = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr_block = "172.100.0.0/16"
private_subnets_additional_tags = {
  "kubernetes.io/role/internal-elb" : "1"
}
public_subnets_additional_tags = {
  "kubernetes.io/role/elb" : "1"
}
# CONFIG LABEL
name_cluster_eks = "example-prod-eks-cluster"
namespace = "example"
stage = "prod"
name = "eks"
subnet_type_tag_key = "SubnetType"
tags = {
    "Name" = "eks-vpc"
    "Centro_de_costos" = "valor"
    "Stage" = "prod"
    "Namespace" = "example"
    "Application" = "eks-example"
    "Version" = "0.1.0"
}
