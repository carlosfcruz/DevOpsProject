# ─────────────────────────────────────────────────────────
# Root Variables
# ─────────────────────────────────────────────────────────
# Top-level input definitions for the project infrastructure.
# Values are typically supplied via tfvars files or CLI parameters.
# ─────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix applied to resource naming"
  type        = string
  default     = "platform"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.small"
}

variable "environment" {
  description = "Target environment identifier (e.g., staging, production)"
  type        = string
  default     = "staging"
}
