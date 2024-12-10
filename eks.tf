# main.tf
provider "aws" {
  region = var.aws_region
}

<<<<<<< Updated upstream
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
=======
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

module "security_groups" {
  source  = "git::https://github.com/drewpypro/terraform-aws-sg-module-template.git?ref=v2.0.0"

  vpc_id = module.vpc.vpc_id

>>>>>>> Stashed changes
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
<<<<<<< Updated upstream
  version = "~> 19.0"
=======
  version = "~> 20.11"
>>>>>>> Stashed changes

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

<<<<<<< Updated upstream
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
=======
  vpc_id                                = module.vpc.vpc_id
  subnet_ids                            = module.vpc.private_subnets
  cluster_endpoint_public_access        = true
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access_cidrs  = var.SOURCE_SSH_NET
  cluster_additional_security_group_ids = module.security_groups.cluster_endpoint_sg.id

  # Grant the Terraform caller administrative access to the cluster
  enable_cluster_creator_admin_permissions = true

  create_iam_role = true
  #   create_iam_role = false
  #   iam_role_arn    = aws_iam_role.eks_cluster_role.arn

  eks_managed_node_group_defaults = {
   iam_role_additional_policies = {
     AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
     AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
   }
  }

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }
>>>>>>> Stashed changes

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    # Worker nodes
    workers = {
      name = "worker"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

<<<<<<< Updated upstream
      min_size     = 2
      max_size     = 2
      desired_size = 2
=======
      min_size        = 2
      max_size        = 2
      desired_size    = 2
>>>>>>> Stashed changes

      labels = {
        role = "worker"
      }
    }

    # Istio ingress nodes
    istio-ingress = {
      name = "istio"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

<<<<<<< Updated upstream
      min_size     = 2
      max_size     = 2
      desired_size = 2
=======
      min_size        = 2
      max_size        = 2
      desired_size    = 2
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access_cidrs = var.SOURCE_SSH_NET
=======
    node_security_group_additional_rules = {
      ingress_15017 = {
        description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
        protocol                      = "TCP"
        from_port                     = 15017
        to_port                       = 15017
        type                          = "ingress"
        source_cluster_security_group = true
      }
      ingress_15012 = {
        description                   = "Cluster API to nodes ports/protocols"
        protocol                      = "TCP"
        from_port                     = 15012
        to_port                       = 15012
        type                          = "ingress"
        source_cluster_security_group = true
      }
    }
>>>>>>> Stashed changes

  tags = {
    Environment = var.environment
  }
<<<<<<< Updated upstream
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.eks.private_subnet_ids
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
=======
>>>>>>> Stashed changes

  depends_on = [
    module.security_groups,
  ]
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
resource "kubernetes_namespace_v1" "istio_system" {
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

# resource "null_resource" "apply_k8s_resources" {
#   depends_on = [module.eks]

#   provisioner "local-exec" {
#     command = "kubectl apply -f kubernetes/"
#   }
# }