# ─────────────────────────────────────────────────────────
# Platform — Terraform Root Module
# ─────────────────────────────────────────────────────────
# Entry point for infrastructure provisioning.
# Configures the AWS provider and integrates modules.
# ─────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend configured for initial stages.
  # Migration to S3 remote backend planned for future.
}

# ─────────────────────────────────────────────────────────
# Provider Configuration
# ─────────────────────────────────────────────────────────
# Directs Terraform interactions with the AWS API.
# Authentication relies on environment variables, local 
# credentials file, or instance profiles.
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
# Networking Module
# ─────────────────────────────────────────────────────────
# Provisions foundational network resources: VPC, subnet,
# internet gateway, and security group.
# ─────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  aws_region   = var.aws_region
}

# ─────────────────────────────────────────────────────────
# Compute Module
# ─────────────────────────────────────────────────────────
# Provisions the core application server (EC2) and SSH keys.
# Relies on network infrastructure attributes (subnet, security group)
# exported by the networking module.
# ─────────────────────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  instance_type     = var.instance_type
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.security_group_id
}
