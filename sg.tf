resource "aws_security_group" "istio_node_sg" {
  name        = "istio-node-sg"
  description = "Security group for Istio Ingress and Egress nodes"
  vpc_id      = module.vpc.vpc_id
}

# Ingress and Egress Rules for Istio Nodes
resource "aws_security_group_ingress_rule" "istio_node_rule1" {
  description                  = "Allow nodes ingress"
  security_group_id            = aws_security_group.istio_node_sg.id
  referenced_security_group_id = aws_security_group.worker_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = module.vpc.private_subnets

  depends_on = [
    aws_security_group.worker_node_sg,
    aws_security_group.cluster_endpoint_sg
    ]
}

resource "aws_security_group_ingress_rule" "istio_node_rule2" {
  description                  = "Allow nodes ingress"
  security_group_id            = aws_security_group.istio_node_sg.id
  referenced_security_group_id = aws_security_group.cluster_endpoint_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = module.vpc.private_subnets

  depends_on = [
    aws_security_group.worker_node_sg,
    aws_security_group.cluster_endpoint_sg
    ]
}

resource "aws_security_group_ingress_rule" "allow_istio_homenet" {
  description                  = "Allow home networks"
  security_group_id            = aws_security_group.istio_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = var.SOURCE_SSH_NET
}

resource "aws_security_group_egress_rule" "istio_egress" {
  description                  = "Allow all outbound traffic"
  security_group_id            = aws_security_group.istio_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = ["0.0.0.0/0"]
}

resource "aws_security_group" "worker_node_sg" {
  name        = "worker-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  depends_on = [
    aws_security_group.istio_node_sg,
    aws_security_group.cluster_endpoint_sg
    ]
}

resource "aws_security_group_ingress_rule" "worker_node_rule1" {
  description                  = "Allow nodes ingress"
  security_group_id            = aws_security_group.worker_node_sg.id
  referenced_security_group_id = aws_security_group.istio_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = module.vpc.private_subnets

  depends_on = [
    aws_security_group.istio_node_sg,
    aws_security_group.cluster_endpoint_sg
    ]
}

resource "aws_security_group_ingress_rule" "worker_node_rule2" {
  description                  = "Allow nodes ingress"
  security_group_id            = aws_security_group.worker_node_sg.id
  referenced_security_group_id = aws_security_group.cluster_endpoint_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = module.vpc.private_subnets

  depends_on = [
    aws_security_group.istio_node_sg,
    aws_security_group.cluster_endpoint_sg
    ]
}

resource "aws_security_group_ingress_rule" "worker_homenet" {
  description                  = "Allow home networks"
  security_group_id            = aws_security_group.istio_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = var.SOURCE_SSH_NET
}

resource "aws_security_group_egress_rule" "worker_egress" {
  description                  = "Allow all outbound traffic"
  security_group_id            = aws_security_group.istio_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = ["0.0.0.0/0"]
}

resource "aws_security_group" "cluster_endpoint_sg" {
  name        = "cluster-endpoint-sg"
  description = "Security group for EKS cluster endpoint access"
  vpc_id      = module.vpc.vpc_id

  depends_on = [
    aws_security_group.istio_node_sg,
    aws_security_group.worker_node_sg
    ]
}

# Ingress and Egress Rules for Cluster Endpoint Access
resource "aws_security_group_ingress_rule" "cluster_endpoint_rule1" {
  description                  = "Allow nodes ingress"
  security_group_id            = aws_security_group.cluster_endpoint_sg.id
  referenced_security_group_id = aws_security_group.istio_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = module.vpc.private_subnets
}

resource "aws_security_group_ingress_rule" "cluster_endpoint_rule2" {
  description                  = "Allow nodes ingress"
  security_group_id            = aws_security_group.cluster_endpoint_sg.id
  referenced_security_group_id = aws_security_group.worker_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = module.vpc.private_subnets
}


resource "aws_security_group_egress_rule" "cluster_endpoint_egress" {
  description              = "Allow all outbound traffic"
  security_group_id        = aws_security_group.cluster_endpoint_sg.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_ipv4                = ["0.0.0.0/0"]
}

resource "aws_security_group_ingress_rule" "allow_cluster_homenet" {
  description                  = "Allow home networks"
  security_group_id            = aws_security_group.istio_node_sg.id
  from_port                    = 0
  to_port                      = 0
  protocol                     = "-1"
  cidr_ipv4                    = var.SOURCE_SSH_NET
}