# ─────────────────────────────────────────────────────────
# Root Outputs
# ─────────────────────────────────────────────────────────
# Consolidates module outputs and provides connection 
# details upon successful execution.
# ─────────────────────────────────────────────────────────

output "server_public_ip" {
  description = "Public IP of the application server"
  value       = module.compute.public_ip
}

output "ssh_command" {
  description = "Constructed SSH connection command"
  value       = "ssh -i platform-key.pem ubuntu@${module.compute.public_ip}"
}
