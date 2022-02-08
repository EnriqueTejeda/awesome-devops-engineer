provider "aws" {
  region = var.region
  shared_credentials_file = "~/.aws/credentials"
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.17.0"
  namespace  = var.namespace
  name       = var.name
  stage      = var.stage
  delimiter  = var.delimiter
  attributes = compact(concat(var.attributes, list("cluster")))
  tags       = var.tags
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
  tags = merge(module.label.tags, map("kubernetes.io/cluster/${var.name_cluster_eks}", "shared"))
}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.15.0"
  name       = module.label.id
  attributes = var.attributes
  cidr_block = var.vpc_cidr_block
  tags       = local.tags
}

module "subnets" {
  source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=tags/0.25.0"
  availability_zones   = var.availability_zones
  name                 = module.label.id
  attributes           = var.attributes
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = true
  nat_instance_enabled = false
  private_subnets_additional_tags = var.private_subnets_additional_tags
  public_subnets_additional_tags = var.public_subnets_additional_tags
  subnet_type_tag_key  = var.subnet_type_tag_key
  tags                 = local.tags
}

