## IAM FOR PRODUCER VM
resource "aws_iam_policy" "test_ec2_policy" {
  name        = "Test_ec2_Policy"
  description = "Policy for Test EC2 instances applied using instance profile"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BadIamPolicy"
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "dms:*",
          "dynamodb:*",
          "ec2:*",
          "eks:*",
          "ec2messages:*",
          "elasticloadbalancing:*",
          "logs:*",
          "monitoring:*",
          "rds:*",
          "s3:*",
          "secretsmanager:*",
          "sns:*",
          "sqs:*",
          "ssm:*",
          "ssmmessages:*",
          "sts:*",
          "iam:CreateServiceLinkedRole",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "test_ec2_role" {
  name = "Test_ec2_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test_policy_attachment" {
  role       = aws_iam_role.test_ec2_role.name
  policy_arn = aws_iam_policy.test_ec2_policy.arn
}

resource "aws_iam_instance_profile" "test_instance_profile" {
  name = "Test_EC2_InstanceProfile"
  role = aws_iam_role.test_ec2_role.name
}

resource "aws_iam_role" "flow_logs_role" {
  name = "flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_policy" "flow_logs_policy" {
  name = "flow-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "flow_logs_role_attachment" {
  role       = aws_iam_role.flow_logs_role.name
  policy_arn = aws_iam_policy.flow_logs_policy.arn
}

## EKS IAM
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_policy" "eks_custom_permissions" {
  name        = "eks-custom-permissions"
  description = "Custom permissions for managing LB security groups in EKS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:*",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "eks_custom_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = aws_iam_policy.eks_custom_permissions.arn
}


# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "eks_worker_custom_permissions" {
  name        = "eks-worker-custom-permissions"
  description = "Custom permissions for EKS worker nodes to manage security groups"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:*",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "eks_worker_custom_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.eks_worker_custom_permissions.arn
}