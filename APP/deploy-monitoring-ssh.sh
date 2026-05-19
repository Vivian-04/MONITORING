#!/bin/bash
set -e

cd "$(dirname "$0")"

if [ -z "${MON_HOST:-}" ]; then
  read -rp "Monitoring server IP or hostname: " MON_HOST
fi
if [ -z "$MON_HOST" ]; then
  echo "ERROR: Monitoring server host cannot be empty."
  exit 1
fi

if [ -z "${SSH_USER:-}" ]; then
  read -rp "SSH user for monitoring server [root]: " SSH_USER
fi
SSH_USER=${SSH_USER:-root}

if [ -z "${SSH_PASSWORD:-}" ]; then
  read -rsp "SSH password for monitoring server user: " SSH_PASSWORD
  echo
fi
if [ -z "$SSH_PASSWORD" ]; then
  echo "ERROR: SSH password cannot be empty."
  exit 1
fi

if [ -z "${SUDO_PASSWORD:-}" ]; then
  SUDO_PASSWORD=$SSH_PASSWORD
fi

if ! command -v sshpass >/dev/null 2>&1; then
  echo "ERROR: sshpass is required for password-based SSH deployment."
  echo "Install it on the machine running Terraform, for example: sudo apt install -y sshpass"
  exit 1
fi

quote_for_remote() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

remote_exec_raw() {
  SSHPASS=$SSH_PASSWORD sshpass -e ssh \
    -o StrictHostKeyChecking=accept-new \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    "${SSH_USER}@${MON_HOST}" "$1"
}

remote_upload_raw() {
  local src=$1
  local dest=$2
  SSHPASS=$SSH_PASSWORD sshpass -e scp \
    -o StrictHostKeyChecking=accept-new \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    "$src" "${SSH_USER}@${MON_HOST}:$dest"
}

remote_exec_root() {
  local command=$1
  local escaped_command
  local escaped_sudo_password

  escaped_command=$(quote_for_remote "$command")

  if [ "$SSH_USER" = "root" ]; then
    remote_exec_raw "bash -lc '$escaped_command'"
  else
    escaped_sudo_password=$(quote_for_remote "$SUDO_PASSWORD")
    remote_exec_raw "printf '%s\n' '$escaped_sudo_password' | sudo -S -p '' bash -lc '$escaped_command'"
  fi
}

if [ -z "${APP_HOST:-}" ]; then
  read -rp "Application server host or IP to monitor [auto-detect]: " APP_HOST
fi
if [ -z "$APP_HOST" ]; then
  APP_HOST=$(hostname -I | awk '{print $1}')
  if [ -z "$APP_HOST" ]; then
    echo "ERROR: Could not auto-detect app host. Please enter it manually."
    exit 1
  fi
  echo "Using application host: $APP_HOST"
fi

if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
  read -rp "Slack webhook URL for Alertmanager notifications: " SLACK_WEBHOOK_URL
fi
if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "ERROR: Slack webhook URL cannot be empty."
  exit 1
fi

if [ -z "${GITHUB_REPOSITORY:-}" ]; then
  read -rp "GitHub repository to monitor (owner/repo): " GITHUB_REPOSITORY
fi
if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "ERROR: GitHub repository cannot be empty."
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  read -rsp "GitHub token for repository metrics (GITHUB_TOKEN): " GITHUB_TOKEN
  echo
fi
if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: GitHub token cannot be empty."
  exit 1
fi

if [ -z "${GRAFANA_ADMIN_USER:-}" ]; then
  read -rp "Grafana admin username [admin]: " GRAFANA_ADMIN_USER
fi
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}

if [ -z "${GRAFANA_ADMIN_PASSWORD:-}" ]; then
  read -rp "Grafana admin password [admin]: " GRAFANA_ADMIN_PASSWORD
fi
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}

REMOTE_DIR=/opt/monitoring
UPLOAD_TAR_LOCAL=./monitoring-upload.tar.gz
UPLOAD_TAR_REMOTE=/tmp/monitoring-upload.tar.gz

echo "Connecting to monitoring server ${SSH_USER}@${MON_HOST}..."

remote_exec_root "mkdir -p ${REMOTE_DIR}"

remote_exec_root "apt update -y && apt install -y git python3 python3-venv gettext-base curl wget tar gzip unzip"

remote_exec_root "rm -rf ${REMOTE_DIR:?}/*"

echo "Archiving local MONITORING folder..."
(cd ../MONITORING && tar -czf ../APP/monitoring-upload.tar.gz .)

echo "Uploading configuration to monitoring server..."
remote_upload_raw "$UPLOAD_TAR_LOCAL" "$UPLOAD_TAR_REMOTE"

echo "Extracting configuration..."
remote_exec_root "tar -xzf $UPLOAD_TAR_REMOTE -C ${REMOTE_DIR}/"
remote_exec_root "rm -f $UPLOAD_TAR_REMOTE"
rm -f "$UPLOAD_TAR_LOCAL"

remote_exec_root "cat > ${REMOTE_DIR}/.env <<'EOF'
APP_HOST=${APP_HOST}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
GITHUB_TOKEN=${GITHUB_TOKEN}
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
EOF"

remote_exec_root "chmod +x ${REMOTE_DIR}/render-configs.sh ${REMOTE_DIR}/setup-monitoring.sh"
remote_exec_root "cd ${REMOTE_DIR} && ./setup-monitoring.sh"

echo "Monitoring stack deployment complete."
echo "Visit Grafana at http://${MON_HOST}:3000"
