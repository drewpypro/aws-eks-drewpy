locals {
  paas_subnets = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]
}

module "security_groups" {
  source  = "git::https://github.com/drewpypro/terraform-aws-sg-module-template.git?ref=v2.0.40"

  vpc_id = module.vpc.vpc_id

}

resource "aws_launch_template" "worker_node_group" {
  name_prefix   = "worker-node-group"

  network_interfaces {
    security_groups = [module.security_groups.security_group_ids["worker_nodes"]]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        "Name" = "worker-node"
      }
    )
  }
}
resource "aws_launch_template" "istio_node_group" {
  name_prefix   = "istio-node-group"

  network_interfaces {
    security_groups = [module.security_groups.security_group_ids["istio_nodes"]]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        "Name" = "istio-node"
      }
    )
  }
}


resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = local.paas_subnets
    endpoint_public_access = true
    endpoint_private_access = true
    public_access_cidrs    = var.SOURCE_SSH_NET
    security_group_ids     = [module.security_groups.security_group_ids["cluster_endpoint"]]
  }

  version = var.cluster_version

  tags = merge(
    var.common_tags,
    {
      "Name" = var.cluster_name
    }
  )

  depends_on = [
    module.security_groups
  ]
}

resource "aws_iam_role" "node_group_role" {
  name               = "eks-node-group-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "eks-node-group-role"
  }
}

resource "aws_iam_role_policy_attachment" "node_group_role_attachments" {
  for_each = {
    "AmazonEKSWorkerNodePolicy"            = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "AmazonEC2ContainerRegistryReadOnly"   = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    "AmazonEKS_CNI_Policy"                 = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    "AdministratorAccess"                  = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  role       = aws_iam_role.node_group_role.name
  policy_arn = each.value
}



# Managed Node Group - Workers
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.eks.name
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = local.paas_subnets
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  launch_template {
    id      = aws_launch_template.worker_node_group.id
    version = "$Latest"
  }

  labels = {
    role = "worker"
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "worker-node-group"
    }
  )

  depends_on = [
    aws_eks_cluster.eks,
    aws_launch_template.worker_node_group,
    aws_vpc_endpoint.service_vpc_endpoints,
    aws_vpc_endpoint.gateway_endpoints
  ]
}

# Managed Node Group - Istio Ingress
resource "aws_eks_node_group" "istio_ingress" {
  cluster_name    = aws_eks_cluster.eks.name
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = local.paas_subnets
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  launch_template {
    id      = aws_launch_template.istio_node_group.id
    version = "$Latest"
  }

  labels = {
    role = "istio-ingress"
  }

  taint {
    key    = "dedicated"
    value  = "istio-ingress"
    effect = "NO_SCHEDULE"
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "istio-ingress-node-group"
    }
  )
  depends_on = [
    aws_eks_cluster.eks,
    aws_launch_template.istio_node_group,
    aws_vpc_endpoint.service_vpc_endpoints,
    aws_vpc_endpoint.gateway_endpoints
  ]
}

# Add-Ons (CoreDNS, kube-proxy, VPC CNI, Pod Identity Agent)
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "coredns"
  depends_on   = [
    aws_eks_cluster.eks,
    aws_eks_node_group.workers
    ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "kube-proxy"
  depends_on   = [
    aws_eks_cluster.eks,
    aws_eks_node_group.workers
    ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "vpc-cni"
  depends_on   = [
    aws_eks_cluster.eks,
    aws_eks_node_group.workers
    ]
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "eks-pod-identity-agent"
  depends_on   = [
    aws_eks_cluster.eks,
    aws_eks_node_group.workers
    ]
}

output "internet_nlb_sg_id" {
  value = module.security_groups.security_group_ids["internet_nlb"]
  description = "The security group ID for internet_nlb"
}

output "security_group_map" {
  value = module.security_groups.security_group_ids
  description = "Map of SGs"
}