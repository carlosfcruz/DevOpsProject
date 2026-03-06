# ─────────────────────────────────────────────────────────
# Compute Module Outputs
# ─────────────────────────────────────────────────────────

output "public_ip" {
  description = "Public IP address of the provisioned EC2 instance"
  value       = aws_instance.main.public_ip
}

output "instance_id" {
  description = "Unique Identifier of the EC2 instance"
  value       = aws_instance.main.id
}

output "private_key_pem" {
  description = "Private SSH key material (sensitive)"
  value       = tls_private_key.main.private_key_pem
  sensitive   = true
}
