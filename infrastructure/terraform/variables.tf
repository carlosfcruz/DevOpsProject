# ─────────────────────────────────────────────────────────
# Root Variables
# ─────────────────────────────────────────────────────────
# These are the top-level inputs for the entire project.
# Values come from staging.tfvars (or CLI flags).
# ─────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  default     = "staging"
}
