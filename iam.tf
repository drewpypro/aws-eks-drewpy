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
