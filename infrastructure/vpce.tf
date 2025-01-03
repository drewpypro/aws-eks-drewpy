# Check hash of files if they change then trigger policy change. 
resource "null_resource" "policy_trigger" {
  triggers = {
    policy = filemd5("${path.module}/policies/vpce_policy.json")
  }
}

resource "null_resource" "s3_policy_trigger" {
  triggers = {
    policy = filemd5("${path.module}/policies/s3_vpce_policy.json")
  }
}

resource "null_resource" "monitoring_policy_trigger" {
  triggers = {
    policy = filemd5("${path.module}/policies/monitoring_vpce_policy.json")
  }
}

resource "aws_vpc_endpoint" "service_vpc_endpoints" {
  for_each            = toset(var.services)
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  policy = templatefile(
    each.key == "monitoring"
    ? "${path.module}/policies/monitoring_vpce_policy.json"
    : "${path.module}/policies/vpce_policy.json",
    {
      service_name = each.key,
      ACCOUNT_ID   = var.ACCOUNT_ID,
      ORG_ID       = var.ORG_ID,
      ORG_PATH     = var.ORG_PATH,
      region       = var.aws_region
    }
  )

  security_group_ids = [module.security_groups.security_group_ids[each.key]]
  subnet_ids         = [module.vpc.private_subnets[0]]

  depends_on = [null_resource.policy_trigger, null_resource.monitoring_policy_trigger]
}

# Gateway Endpoints for S3 and RDS
resource "aws_vpc_endpoint" "gateway_endpoints" {
  for_each          = toset(var.gateway_services)
  vpc_id            = aws_vpc.test_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.test_rt_1.id]

  policy = templatefile(
    "${path.module}/policies/s3_vpce_policy.json",
    {
      service_name = each.key,
      ACCOUNT_ID   = var.ACCOUNT_ID,
      ORG_ID       = var.ORG_ID,
      ORG_PATH     = var.ORG_PATH,
      region       = var.aws_region
    }
  )

  depends_on = [null_resource.s3_policy_trigger]
}
