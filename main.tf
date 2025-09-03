terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "aws" {
  region = var.region
}

# Kubernetes provider configured via EKS module outputs
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = module.eks.cluster_auth_token
  depends_on             = [module.eks]
}

# -----------------------------
# VPC
# -----------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# -----------------------------
# EKS Cluster
# -----------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31.2"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = [var.node_instance_type]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# -----------------------------
# ECR Repository for NGINX
# -----------------------------
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
  }
}

# -----------------------------
# Optional: Outputs
# -----------------------------
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_kubeconfig_token" {
  value = module.eks.cluster_auth_token
}
