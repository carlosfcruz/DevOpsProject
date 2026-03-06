# ─────────────────────────────────────────────────────────
# Networking Module — Input Variables
# ─────────────────────────────────────────────────────────
# These are the "parameters" of the module.
# The root main.tf passes values in when calling the module.
# ─────────────────────────────────────────────────────────

variable "project_name" {
  description = "Name prefix for all resources (e.g. 'platform')"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. '10.0.0.0/16' = 65,536 IPs)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (e.g. '10.0.1.0/24' = 256 IPs)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_region" {
  description = "AWS region (used to pick availability zone)"
  type        = string
}
