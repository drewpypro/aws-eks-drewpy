terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # backend "s3" {
  #   skip_credentials_validation = true
  #   skip_requesting_account_id  = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   skip_s3_checksum            = true
  #   region                      = "us-east-1"
  # }
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}

provider "aws" {
  region = var.aws_region
}
