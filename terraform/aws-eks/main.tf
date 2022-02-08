provider "aws" {
  region = var.region
  shared_credentials_file = "~/.aws/credentials"
}

locals {
  # PUBLIC SUBNETS
  subnet_ids_string_public = join(",", data.aws_subnet_ids.public.ids)
  subnet_ids_list_public = split(",", local.subnet_ids_string_public)
  # PRIVATE SUBNETS
  subnet_ids_string = join(",", data.aws_subnet_ids.private.ids)
  subnet_ids_list = split(",", local.subnet_ids_string)
  # ALL SUBNETS
  subnet_ids_string_all = join(",", data.aws_subnet_ids.all.ids)
  subnet_ids_list_all = split(",", local.subnet_ids_string_all)
  tags = merge(module.label.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))

  # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
  # variable does not work as expected, if you are not going to use custom ami you should
  # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
  # otherwise will be used the first version of Kubernetes supported by AWS (v1.11) for EKS workers but
  # EKS control plane will use the version specified by kubernetes_version variable.
  eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"
}

data "aws_vpc" "selected" {
  state = "available"
  tags = var.data_vpc_tags
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.selected.id
  filter {
    name   = "tag:SubnetType"
    values = ["public"]
  }
}

data "aws_subnet"  "individual_public" {
  count = length(data.aws_subnet_ids.public.ids)
  id    = local.subnet_ids_list_public[count.index]
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id
  filter {
    name   = "tag:SubnetType"
    values = ["private"]
  }
}

data "aws_subnet"  "individual_private" {
  count = length(data.aws_subnet_ids.private.ids)
  id    = local.subnet_ids_list[count.index]
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet"  "individual_all" {
  count = length(data.aws_subnet_ids.all.ids)
  id    = local.subnet_ids_list_all[count.index]
}

data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.eks_cluster.eks_cluster_id
    kubernetes_config_map_id = module.eks_cluster.kubernetes_config_map_id
    security_group_id        = module.eks_cluster.eks_cluster_managed_security_group_id
  }
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

module "eks_cluster" {
  source     = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=tags/0.29.1"
  region     = var.region
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  tags       = local.tags
  vpc_id     = data.aws_vpc.selected.id
  endpoint_private_access = true
  endpoint_public_access = true # To false later
  subnet_ids = tolist(data.aws_subnet.individual_all.*.id)

  kubernetes_version = var.kubernetes_version
  oidc_provider_enabled = var.oidc_provider_enabled
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period
}

module "eks_node_group_ondemand_production_t3"   {
  source             = "git::https://github.com/cloudposse/terraform-aws-eks-node-group.git?ref=tags/0.15.0"
  namespace          = var.namespace
  stage              = var.stage
  name               = "${var.name}-ondemand-production-t3"
  attributes         = var.attributes
  tags               = var.tags
  subnet_ids         = tolist(data.aws_subnet.individual_private.*.id)
  instance_types     = ["t3.medium"]
  desired_size       = 1
  min_size           = 1
  max_size           = 3
  disk_size          = var.disk_size
  cluster_name       = data.null_data_source.wait_for_cluster_and_kubernetes_configmap.outputs["cluster_name"]
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  resources_to_tag = ["instance", "volume", "elastic-gpu", "spot-instances-request"]
  kubernetes_version = var.kubernetes_version
}

# data "aws_iam_group" "default" {
#   group_name = var.iam_group_policy_eks
# }

# resource "aws_iam_policy" "default" {
#   name        = "eks-full-AmazonEKSAdminPolicy"
#   description = "Full access to EKS Service"
#   policy      = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#       {
#           "Effect": "Allow",
#           "Action": [
#               "eks:*"
#           ],
#           "Resource": "*"
#       },
#       {
#           "Effect": "Allow",
#           "Action": "iam:PassRole",
#           "Resource": "*",
#           "Condition": {
#               "StringEquals": {
#                   "iam:PassedToService": "eks.amazonaws.com"
#               }
#           }
#       }
#   ]
# }
#   EOF
# }
# resource "aws_iam_group_policy_attachment" "default" {
#   group      = data.aws_iam_group.default.group_name
#   policy_arn = aws_iam_policy.default.arn
# }
