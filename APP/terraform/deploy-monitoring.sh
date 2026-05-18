#!/bin/bash
set -e

cd "$(dirname "$0")"

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

read -rp "Grafana admin username [admin]: " GRAFANA_ADMIN_USER
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}

read -rp "Grafana admin password [admin]: " GRAFANA_ADMIN_PASSWORD
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}

terraform init

terraform apply -auto-approve \
  -var="app_host=${APP_HOST}" \
  -var="slack_webhook_url=${SLACK_WEBHOOK_URL}" \
  -var="grafana_admin_user=${GRAFANA_ADMIN_USER}" \
  -var="grafana_admin_password=${GRAFANA_ADMIN_PASSWORD}"
