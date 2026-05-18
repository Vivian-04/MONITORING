#!/bin/bash
set -e

cd "$(dirname "$0")"

read -rp "Monitoring server host or IP: " MONITORING_HOST
if [ -z "${MONITORING_HOST}" ]; then
  echo "ERROR: monitoring host cannot be empty."
  exit 1
fi

read -rp "SSH user for monitoring server [root]: " SSH_USER
SSH_USER=${SSH_USER:-root}

read -rp "Application server host or IP to monitor: " APP_HOST
if [ -z "${APP_HOST}" ]; then
  echo "ERROR: app host cannot be empty."
  exit 1
fi

read -rp "Slack webhook URL for Alertmanager: " SLACK_WEBHOOK_URL
if [ -z "${SLACK_WEBHOOK_URL}" ]; then
  echo "ERROR: Slack webhook URL cannot be empty."
  exit 1
fi

read -rp "GitHub repository to monitor (owner/repo): " GITHUB_REPOSITORY
if [ -z "${GITHUB_REPOSITORY}" ]; then
  echo "ERROR: GitHub repository cannot be empty."
  exit 1
fi

read -rsp "GitHub token for repository metrics: " GITHUB_TOKEN
echo
if [ -z "${GITHUB_TOKEN}" ]; then
  echo "ERROR: GitHub token cannot be empty."
  exit 1
fi

read -rp "Grafana admin username [admin]: " GRAFANA_ADMIN_USER
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}

read -rp "Grafana admin password [admin]: " GRAFANA_ADMIN_PASSWORD
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}

terraform init

terraform apply -auto-approve \
  -var="monitoring_host=${MONITORING_HOST}" \
  -var="ssh_user=${SSH_USER}" \
  -var="app_host=${APP_HOST}" \
  -var="slack_webhook_url=${SLACK_WEBHOOK_URL}" \
  -var="github_repository=${GITHUB_REPOSITORY}" \
  -var="github_token=${GITHUB_TOKEN}" \
  -var="grafana_admin_user=${GRAFANA_ADMIN_USER}" \
  -var="grafana_admin_password=${GRAFANA_ADMIN_PASSWORD}"
