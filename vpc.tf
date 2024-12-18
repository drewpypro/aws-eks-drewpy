# VPC and Networking
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = [
    var.private_subnet_cidrs["eks-a"],
    var.private_subnet_cidrs["eks-b"],
    var.private_subnet_cidrs["general-a"],
    var.private_subnet_cidrs["general-b"],
    var.private_subnet_cidrs["endpoint-a"],
    var.private_subnet_cidrs["endpoint-b"]
  ]

  public_subnets = [
    var.public_subnet_cidrs["internet-nlb-a"],
    var.public_subnet_cidrs["internet-nlb-b"]
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_flow_log      = false

  tags = merge(
    var.common_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )

  private_subnet_tags = merge(
    var.common_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    }
  )

  public_subnet_tags = merge(
    var.common_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    }
  )
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = "/aws/vpc/${var.cluster_name}-vpc-flow-logs"
  retention_in_days = 1
  skip_destroy      = false
  
  depends_on = [aws_flow_log.vpc_flow_log]
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  vpc_id               = module.vpc.vpc_id
  traffic_type         = "ALL"

}

resource "aws_route53_resolver_query_log_config" "query_log_config" {
  name           = "${var.cluster_name}-dns-query-logs"
  destination_arn = aws_cloudwatch_log_group.dns_query_log_group.arn
}

resource "aws_route53_resolver_query_log_config_association" "query_log_config_assoc" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.query_log_config.id
  resource_id                  = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "dns_query_log_group" {
  name              = "/aws/vpc/${var.cluster_name}-dns-query-logs"
  retention_in_days = 1
  skip_destroy      = false
}

