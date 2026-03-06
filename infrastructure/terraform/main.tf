# ─────────────────────────────────────────────────────────
# Platform — Terraform Root Module
# ─────────────────────────────────────────────────────────
# This file is the entry point for all infrastructure.
# Right now it only configures the AWS provider.
# We'll add modules (networking, compute) in later sessions.
# ─────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Session 1: local backend (state stored on disk)
  # Session 6: we'll migrate this to S3 remote backend
}

# ─────────────────────────────────────────────────────────
# Provider: tells Terraform HOW to talk to AWS
# ─────────────────────────────────────────────────────────
# It reads credentials from:
#   1. Environment vars (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
#   2. ~/.aws/credentials file (from `aws configure`)
#   3. EC2 instance profile (if running on AWS)
# ─────────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Platform"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# ─────────────────────────────────────────────────────────
# Module: Networking
# ─────────────────────────────────────────────────────────
# Creates VPC, subnet, internet gateway, and security group.
# Think of it as: "build the neighborhood before the house"
# ─────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  aws_region   = var.aws_region
}
