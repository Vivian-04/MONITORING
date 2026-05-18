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
REMOTE_CLONE_DIR=/tmp/monitoring-repo
REMOTE_REPO=https://github.com/Vivian-04/MONITORING.git

echo "Connecting to monitoring server ${SSH_USER}@${MON_HOST}..."

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }mkdir -p ${REMOTE_DIR}"

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }apt update -y && ${REMOTE_SUDO:+$REMOTE_SUDO }apt install -y git"

ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }rm -rf ${REMOTE_DIR}/*"
ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }rm -rf ${REMOTE_CLONE_DIR}"
ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }git clone ${REMOTE_REPO} ${REMOTE_CLONE_DIR}"
ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }cp -a ${REMOTE_CLONE_DIR}/MONITORING/. ${REMOTE_DIR}/"
ssh "${SSH_USER}@${MON_HOST}" "${REMOTE_SUDO:+$REMOTE_SUDO }rm -rf ${REMOTE_CLONE_DIR}"

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
