# -----------------------------
# Global Variables
# -----------------------------

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-2" # change if needed
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "our-eks-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "ecr_repository" {
  description = "ECR repository name for the app"
  type        = string
  default     = "nginx-app"
}
