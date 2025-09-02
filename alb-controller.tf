# -------------------------------
# IAM Policy for AWS Load Balancer Controller
# -------------------------------
data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.alb_iam_policy.response_body
}

# -------------------------------
# IAM Role for ServiceAccount (IRSA)
# -------------------------------
module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-alb-controller"

  # Fixed: map of string
  role_policy_arns = {
    "alb-controller" = aws_iam_policy.alb_controller.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# -------------------------------
# Kubernetes Namespace + Service Account
# -------------------------------
resource "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }
}

resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.alb_controller_irsa.iam_role_arn
    }
  }
}

# -------------------------------
# Install AWS Load Balancer Controller via manifest
# -------------------------------
resource "null_resource" "install_alb_controller" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl apply -k "github.com/kubernetes-sigs/aws-load-balancer-controller//config/default?ref=v2.7.1"
      kubectl -n kube-system set env deployment/aws-load-balancer-controller \
        AWS_VPC_ID=${module.vpc.vpc_id} \
        AWS_REGION=${var.region} \
        CLUSTER_NAME=${var.cluster_name}
    EOT
  }

  depends_on = [
    module.eks,
    kubernetes_service_account.alb_controller
  ]
}