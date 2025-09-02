# -------------------------------
# Terraform input variables
# -------------------------------

variable "region" {
  description = "AWS region to deploy resources"
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "our-eks-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  default     = "t3.medium"
}
