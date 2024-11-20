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
  enable_flow_log      = true

  flow_log_destination_arn   = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  vpc_flow_log_iam_role_name = aws_iam_role.flow_logs_role.name

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


resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = "/aws/vpc/${var.cluster_name}-flow-logs"
  retention_in_days = 1
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  vpc_id               = module.vpc.vpc_id
  traffic_type         = "ALL"
}
