locals {
  name = "${var.project_name}-${var.environment}"
  azs  = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  tags = { Project = var.project_name, Environment = var.environment, ManagedBy = "Terraform" }
}

data "aws_availability_zones" "available" { state = "available" }

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name    = local.name
  cidr    = var.vpc_cidr
  azs     = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true # cost-conscious development default; use one per AZ in production
  enable_dns_hostnames = true
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  cluster_name    = local.name
  cluster_version = var.cluster_version
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      desired_size   = var.node_desired_size
      max_size       = var.node_max_size
    }
  }
  cluster_addons = { coredns = {}, kube-proxy = {}, vpc-cni = {}, eks-pod-identity-agent = {} }
}
