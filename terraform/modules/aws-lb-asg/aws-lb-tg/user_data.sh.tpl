#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> [user-data] $*" | tee -a /var/log/user-data.log
}

SSH_KEY_DIR="/home/ec2-user/.ssh"
SSH_KEY_FILE="$${SSH_KEY_DIR}/github_deploy_key"

log "Waiting for Docker to be ready..."

until docker info >/dev/null 2>&1; do
  sleep 2
done

log "Preparing SSH directory..."

install -d \
  -m 700 \
  -o ec2-user \
  -g ec2-user \
  "$${SSH_KEY_DIR}"

log "Writing SSH deploy key..."

cat > "$${SSH_KEY_FILE}" << 'EOF_DEPLOY_KEY'
${github_ssh_key}
EOF_DEPLOY_KEY

chmod 600 "$${SSH_KEY_FILE}"
chown ec2-user:ec2-user "$${SSH_KEY_FILE}"

log "Adding GitHub to known_hosts..."

ssh-keyscan -H github.com > "$${SSH_KEY_DIR}/known_hosts" 2>/dev/null
chmod 644 "$${SSH_KEY_DIR}/known_hosts"
chown ec2-user:ec2-user "$${SSH_KEY_DIR}/known_hosts"

log "Cloning repository..."

GIT_SSH_COMMAND="ssh -i $${SSH_KEY_FILE} -o IdentitiesOnly=yes -o UserKnownHostsFile=$${SSH_KEY_DIR}/known_hosts" \
  git clone "${repo_url}" "${app_dir}"

log "Setting app directory ownership..."

chown -R ec2-user:ec2-user "${app_dir}"

log "Starting Docker Compose services..."

cd "${app_dir}"

log "Writing .env file..."
install -m 600 -o ec2-user -g ec2-user /dev/null "${app_dir}/.env"
cat > "${app_dir}/.env" << 'EOF_ENV'
APP_SECRET=${app_secret}
APP_VIRTUAL_HOST=${app_virtual_host}
EOF_ENV
chown ec2-user:ec2-user "${app_dir}/.env"

sudo -u ec2-user docker compose \
  -f "docker-compose-${deploy_env}.yaml" \
  up -d

log "Done."
