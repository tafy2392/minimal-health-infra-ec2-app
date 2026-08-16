packer {
  required_version = "~> 1.15.4"

  required_plugins {
    amazon = {
      version = "~> 1.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
  ami_name  = "${var.ami_name_prefix}-${local.timestamp}"
}

source "amazon-ebs" "al2023" {
  region        = var.aws_region
  instance_type = var.instance_type

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile
  communicator                = "ssh"
  ssh_username                = "ec2-user"
  ssh_interface               = "session_manager"
  ami_name                    = local.ami_name

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = local.ami_name
    Base        = "al2023"
    Environment = var.environment
    ManagedBy   = "packer"
    BuildDate   = local.timestamp
  }
}

build {
  name    = "golden-ami"
  sources = ["source.amazon-ebs.al2023"]

  provisioner "shell" {
    script = var.install_script
    environment_vars = [
      "ENVIRONMENT=${var.environment}",
    ]
    timeout = "15m"
  }

  post-processor "manifest" {
    output     = "${path.root}/../ami_manifest.json"
    strip_path = true
  }
}
