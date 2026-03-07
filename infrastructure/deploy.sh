#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# Platform Orchestrator
# ─────────────────────────────────────────────────────────
# Executes the complete deployment lifecycle from raw infrastructure
# to a live, configured application.
# 
# Usage: ./deploy.sh
# ─────────────────────────────────────────────────────────

set -euo pipefail

# ─── Define Paths ───
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform"
ANSIBLE_DIR="${ROOT_DIR}/ansible"

echo "========================================================"
echo "🚀 Initiating Platform Deployment Pipeline"
echo "========================================================"

# ─── 1. Infrastructure Provisioning ───
echo ""
echo "▶ Phase 1: Terraform (Infrastructure as Code)"
echo "--------------------------------------------------------"
cd "$TERRAFORM_DIR"

echo "[1/3] Initializing Terraform backend..."
terraform init -migrate-state

echo "[2/3] Formatting configuration files..."
terraform fmt -recursive

echo "[3/3] Applying infrastructure configuration (Staging)..."
# Using -auto-approve for true CI/CD pipeline simulation
terraform apply -var-file="staging.tfvars" -auto-approve


# ─── 2. Configuration Management ───
echo ""
echo "▶ Phase 2: Ansible (Configuration Management)"
echo "--------------------------------------------------------"
cd "$ANSIBLE_DIR"

echo "[1/2] Generating dynamic SSH inventory..."
chmod +x generate-inventory.sh
./generate-inventory.sh

echo "[2/3] Generating secure database credentials..."
# Use environment variables if set (e.g., from CI secrets), otherwise generate securely
export DB_USER=${DB_USER:-"platform"}
export DB_NAME=${DB_NAME:-"platform"}
export DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)}

echo "[3/3] Executing main sequence playbook (site.yml)..."
# Setting ANSIBLE_HOST_KEY_CHECKING=False as a fallback environment variable
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook playbooks/site.yml \
  --extra-vars "postgres_user=$DB_USER postgres_db=$DB_NAME postgres_password=$DB_PASSWORD"

# ─── 3. Final Verification ───
echo ""
echo "========================================================"
echo "✅ Deployment Complete!"
echo "========================================================"
SERVER_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw server_public_ip)
echo "Your platform is live at: http://${SERVER_IP}.nip.io/dashboard"
echo "SSH access:               ssh -i ansible/platform-key.pem ubuntu@${SERVER_IP}"
echo "========================================================"
