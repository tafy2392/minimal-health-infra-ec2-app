#!/usr/bin/env bash
set -euo pipefail

log() { echo "==> [golden-ami] $*"; }

log "Updating all system packages..."
sudo dnf update -y

# Ensure dnf config-manager plugin is present (required to add repos)
sudo dnf install -y dnf-plugins-core

log "Installing / updating Git..."
sudo dnf install -y git
git --version

log "Installing Python 3.13 and pip..."
sudo dnf install -y python3.13 python3.13-pip
log "Upgrading pip..."
python3.13 -m pip install --upgrade pip

log "Adding Docker CE repository..."
sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null << 'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/rhel/9/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/rhel/gpg
EOF

log "Installing Docker dependencies from AL2023 repos..."
sudo dnf install -y container-selinux iptables-nft nftables

log "Installing Docker CE, CLI, containerd, Buildx, and Compose plugin..."
sudo dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

log "Enabling Docker service on boot..."
sudo systemctl enable docker

log "Adding ec2-user to the docker group..."
sudo usermod -aG docker ec2-user

log "Installing CloudWatch agent..."
sudo dnf install -y amazon-cloudwatch-agent

log "Configuring CloudWatch agent for memory metrics..."
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOF'
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent",
          "mem_available_percent",
          "mem_used",
          "mem_total"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}"
    }
  }
}
EOF

log "Enabling CloudWatch agent on boot..."
sudo systemctl enable amazon-cloudwatch-agent

log "Pointing python3/pip3 to 3.13..."
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1
sudo alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.13 1

log "Verifying installed versions..."
git --version
python3 --version
pip3 --version
docker --version
docker compose version

log "Provisioning complete."
