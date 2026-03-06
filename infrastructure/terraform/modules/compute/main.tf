# ─────────────────────────────────────────────────────────
# Compute Module
# ─────────────────────────────────────────────────────────
# Provisions the EC2 instance and the associated SSH key pair.
# ─────────────────────────────────────────────────────────

# ───── SSH Key Pair ─────
# Generates an RSA private key locally. The public key is 
# registered as an AWS Key Pair for SSH access to the instance.
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main.public_key_openssh
}

# ───── AMI Data Source ─────
# Dynamically queries AWS for the latest Ubuntu 22.04 LTS AMI
# published by Canonical. Avoids hardcoding region-specific AMIs.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical AWS Account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ───── EC2 Instance ─────
# Provisions the application server using the retrieved AMI,
# attaches the SSH key, and places it within the designated 
# subnet and security group defined by the networking module.
resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

  # Network placement
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  # Storage configuration
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-server"
  }
}
