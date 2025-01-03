# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-drewpy"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = map(string)
  default     = {
    "internet-nlb-a" = "10.0.101.0/24"
    "internet-nlb-b" = "10.0.102.0/24"
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = map(string)
  default     = {
    "eks-a"       = "10.0.1.0/24"
    "eks-b"       = "10.0.2.0/24"
    "general-a"   = "10.0.3.0/24"
    "general-b"   = "10.0.4.0/24"
    "endpoint-a"  = "10.0.5.0/24"
    "endpoint-b"  = "10.0.6.0/24"
  }
}

variable "HOME_IP" {
  description = "Public IP to SSH to consumer ec2"
  type        = string
}

variable "SOURCE_SSH_NET" {
  description = "Public IP to SSH to consumer ec2"
  type        = list(string)
}

variable "PUBLIC_KEY" {
  description = "Public SSH key"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    "Environment" = "drewpy-dev"
    "Provisioner_Repo"        = "https://github.com/drewpypro/aws-eks-drewpy"
  }
}

variable "CLOUDFLARE_API_TOKEN" {
  description = "cloudflare api token"
  type = string
}

variable "CLOUDFLARE_ZONE_ID" {
  type        = string
  description = "Cloudflare Zone ID"
}

# Define a list of services that need VPC endpoints
variable "services" {
  default = ["autoscaling", "dms", "ec2", "ec2messages",
    "elasticloadbalancing", "logs", "monitoring", "rds",
    "secretsmanager", "sns", "sqs", "ssm",
  "ssmmessages", "sts", ]
}

variable "gateway_services" {
  default = ["dynamodb", "s3"]
}

variable "ORG_ID" {
  description = "org-id must be configured in your aws accounts and supplied as a variable"
  type        = string
}

variable "ORG_PATH" {
  description = "OU Path must be configured in your aws accounts and supplied as a variable"
  type        = string
}

variable "ACCOUNT_ID" {
  description = "An account must be created prior to test and this is mandatory variable"
  type        = string
}