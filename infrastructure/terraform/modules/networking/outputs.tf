# ─────────────────────────────────────────────────────────
# Networking Module — Outputs
# ─────────────────────────────────────────────────────────
# These values are "returned" to whoever uses this module.
# The compute module will need the subnet ID and SG ID
# to know WHERE to place the EC2 instance.
# ─────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet (EC2 goes here)"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the security group (firewall rules)"
  value       = aws_security_group.main.id
}
