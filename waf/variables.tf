variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "CLOUDFLARE_API_TOKEN" {
  description = "cloudflare api token"
  type = string
}

variable "CLOUDFLARE_ZONE_ID" {
  type        = string
  description = "Cloudflare Zone ID"
}
