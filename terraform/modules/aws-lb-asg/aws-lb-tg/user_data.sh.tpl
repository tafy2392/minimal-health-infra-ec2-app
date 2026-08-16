#!/usr/bin/env bash
set -euo pipefail

log() { echo "==> [user-data] $*" | tee -a /var/log/user-data.log; }

log "Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do sleep 2; done

log "Fetching SSH deploy key from SSM..."
SSH_KEY_DIR="/home/ec2-user/.ssh"
SSH_KEY_FILE="$${SSH_KEY_DIR}/github_deploy_key"
mkdir -p "$${SSH_KEY_DIR}"
aws ssm get-parameter \
  --name "${github_token_ssm_param}" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region "${aws_region}" > "$${SSH_KEY_FILE}"
chmod 600 "$${SSH_KEY_FILE}"
chown ec2-user:ec2-user "$${SSH_KEY_DIR}" "$${SSH_KEY_FILE}"

log "Adding GitHub to known_hosts..."
ssh-keyscan -H github.com >> "$${SSH_KEY_DIR}/known_hosts" 2>/dev/null
chown ec2-user:ec2-user "$${SSH_KEY_DIR}/known_hosts"

log "Cloning repository..."
GIT_SSH_COMMAND="ssh -i $${SSH_KEY_FILE} -o StrictHostKeyChecking=no" \
  git clone "${repo_url}" "${app_dir}"

log "Setting app directory ownership..."
chown -R ec2-user:ec2-user "${app_dir}"

log "Starting Docker Compose services..."
cd "${app_dir}"
sudo -u ec2-user docker compose -f "docker-compose-${deploy_env}.yaml" up -d

log "Done."
