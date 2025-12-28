provider "aws" {
  region = "us-east-1"
}

# 1. إنشاء شبكة VPC مخصصة للـ Kubernetes
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "devops-project-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}

# 2. إنشاء الـ EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "devops-advanced-cluster"
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    nodes = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.medium"] # الـ Nodes تحتاج ذاكرة أكبر من t2.micro
    }
  }
}