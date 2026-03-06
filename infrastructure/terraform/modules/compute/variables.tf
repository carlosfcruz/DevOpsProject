# ─────────────────────────────────────────────────────────
# Compute Module Variables
# ─────────────────────────────────────────────────────────

variable "project_name" {
  description = "Prefix for resource naming"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "ID of the target subnet for instance placement"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group to attach to the instance"
  type        = string
}
