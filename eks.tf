# main.tf
provider "aws" {
  region = var.aws_region
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    # Worker nodes
    workers = {
      name = "worker"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size        = 2
      max_size        = 2
      desired_size    = 2
      security_groups = [aws_security_group.worker_node_sg.id]

      labels = {
        role = "worker"
      }
    }

    # Istio ingress nodes
    istio-ingress = {
      name = "istio"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size        = 2
      max_size        = 2
      desired_size    = 2
      security_groups = [aws_security_group.istio_node_sg.id]

      labels = {
        role = "istio-ingress"
      }

      taints = [{
        key    = "dedicated"
        value  = "istio-ingress"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  cluster_endpoint_public_access        = true
  cluster_endpoint_private_access       = false
  cluster_endpoint_public_access_cidrs  = var.SOURCE_SSH_NET
  cluster_additional_security_group_ids = [aws_security_group.cluster_endpoint_sg.id]

  tags = {
    Environment = var.environment
  }
}

# output "private_subnet_ids" {
#   description = "List of private subnet IDs"
#   value       = module.eks.private_subnet_ids
# }

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

# Helm provider for installing Istio
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    }
  }
}

# Install Istio using Helm
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"

  depends_on = [
    module.eks,
    kubernetes_namespace.istio_system
  ]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"

  depends_on = [
    module.eks,
    kubernetes_namespace.istio_system
  ]
}

# Install Istio ingress gateway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  set {
    name  = "gateways.istio-ingressgateway.enabled"
    value = "true"
  }
  depends_on = [helm_release.istiod]
}

# Install Istio egress gateway
resource "helm_release" "istio_egress" {
  name       = "istio-egressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  set {
    name  = "gateways.istio-egressgateway.enabled"
    value = "true"
  }
  depends_on = [helm_release.istiod]
}


# Create Istio System Namespace
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_namespace" "namespace1" {
  metadata {
    name = "namespace1"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_namespace" "namespace2" {
  metadata {
    name = "namespace2"
    labels = {
      istio-injection = "enabled"
    }
  }
}

# Example application deployment in namespace1
resource "kubernetes_deployment" "app1" {
  metadata {
    name      = "app1"
    namespace = kubernetes_namespace.namespace1.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app1"
      }
    }

    template {
      metadata {
        labels = {
          app = "app1"
        }
      }

      spec {
        container {
          name  = "application"
          image = "nginx:latest"
        }
      }
    }
  }
}

# Example application deployment in namespace2
resource "kubernetes_deployment" "app2" {
  metadata {
    name      = "app2"
    namespace = kubernetes_namespace.namespace2.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app2"
      }
    }

    template {
      metadata {
        labels = {
          app = "app2"
        }
      }

      spec {
        container {
          name  = "application"
          image = "nginx:latest"
        }
      }
    }
  }
}

resource "null_resource" "apply_k8s_resources" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "kubectl apply -f kubernetes/"
  }
}