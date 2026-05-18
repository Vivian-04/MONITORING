#!/bin/bash
set -e

cd "$(dirname "$0")"

read -rp "Monitoring server IP or hostname: " MON_HOST
if [ -z "$MON_HOST" ]; then
  echo "ERROR: Monitoring server host cannot be empty."
  exit 1
fi

read -rp "SSH user for monitoring server [root]: " SSH_USER
SSH_USER=${SSH_USER:-root}

if [ "$SSH_USER" != "root" ]; then
  echo "Using non-root SSH user: ${SSH_USER}. Remote sudo privileges are required."
  REMOTE_SUDO="sudo"
  if ! ssh "${SSH_USER}@${MON_HOST}" "sudo -n true" >/dev/null 2>&1; then
    echo "ERROR: SSH user ${SSH_USER} does not have passwordless sudo access on the remote host."
    exit 1
  fi
else
  REMOTE_SUDO=""
fi

read -rp "Application server host or IP to monitor [auto-detect]: " APP_HOST
if [ -z "$APP_HOST" ]; then
  APP_HOST=$(hostname -I | awk '{print $1}')
  if [ -z "$APP_HOST" ]; then
    echo "ERROR: Could not auto-detect app host. Please enter it manually."
    exit 1
  fi
  echo "Using application host: $APP_HOST"
fi

read -rp "Slack webhook URL for Alertmanager notifications: " SLACK_WEBHOOK_URL
if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "ERROR: Slack webhook URL cannot be empty."
  exit 1
fi

read -rp "GitHub repository to monitor (owner/repo): " GITHUB_REPOSITORY
if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "ERROR: GitHub repository cannot be empty."
  exit 1
fi

read -rsp "GitHub token for repository metrics (GITHUB_TOKEN): " GITHUB_TOKEN
echo
if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: GitHub token cannot be empty."
  exit 1
fi

read -rp "Grafana admin username [admin]: " GRAFANA_ADMIN_USER
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}

read -rp "Grafana admin password [admin]: " GRAFANA_ADMIN_PASSWORD
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}

REMOTE_DIR=/opt/monitoring
REMOTE_REPO=https://github.com/Vivian-04/MONITORING.git

echo "Connecting to monitoring server ${SSH_USER}@${MON_HOST}..."

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }mkdir -p ${REMOTE_DIR}"

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }apt update -y && ${REMOTE_SUDO:+$REMOTE_SUDO }apt install -y git"

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }rm -rf ${REMOTE_DIR}/*"
ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }git clone ${REMOTE_REPO} ${REMOTE_DIR}"

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }bash -lc 'cat > ${REMOTE_DIR}/.env <<EOF
APP_HOST=${APP_HOST}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
GITHUB_TOKEN=${GITHUB_TOKEN}
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
EOF'"

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }chmod +x ${REMOTE_DIR}/render-configs.sh ${REMOTE_DIR}/setup-monitoring.sh"
ssh "${SSH_USER}@${MON_HOST}" "cd ${REMOTE_DIR} && ${REMOTE_SUDO:+$REMOTE_SUDO }./setup-monitoring.sh"

echo "Monitoring stack deployment complete."
echo "Visit Grafana at http://${MON_HOST}:3000"
