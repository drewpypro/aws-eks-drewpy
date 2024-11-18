# main.tf
provider "aws" {
  region = var.aws_region
}

# VPC and Networking
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
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

      min_size     = 2
      max_size     = 2
      desired_size = 2

      labels = {
        role = "worker"
      }
    }

    # Istio ingress nodes
    istio-ingress = {
      name = "istio"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 2
      desired_size = 2

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

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access_cidrs     = ["0.0.0.0/0"]

  tags = {
    Environment = var.environment
  }
}

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

  depends_on = [module.eks]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"

  depends_on = [helm_release.istio_base]
}

# Create namespaces
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