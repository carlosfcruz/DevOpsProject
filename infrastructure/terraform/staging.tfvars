# ─────────────────────────────────────────────────────────
# Staging Environment Variables
# ─────────────────────────────────────────────────────────
# Specifies values for the variables defined in variables.tf 
# corresponding to the staging environment.
# 
# Usage: terraform apply -var-file="staging.tfvars"
# ─────────────────────────────────────────────────────────

environment   = "staging"
project_name  = "platform"
aws_region    = "us-east-1"
instance_type = "t3.small"
