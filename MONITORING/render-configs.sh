#!/bin/bash
set -e

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

if [ -z "${APP_HOST}" ] ; then
  echo "ERROR: APP_HOST must be set to the application server hostname or IP address."
  echo "Set APP_HOST in .env before running this script."
  exit 1
fi

if [ -z "${SLACK_WEBHOOK_URL}" ]; then
  echo "ERROR: SLACK_WEBHOOK_URL must be set for Alertmanager Slack notifications."
  exit 1
fi

if [ -z "${GITHUB_REPOSITORY}" ]; then
  echo "ERROR: GITHUB_REPOSITORY must be set to owner/repo for the GitHub Actions exporter."
  exit 1
fi

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "ERROR: GITHUB_TOKEN must be set for GitHub Actions metrics collection."
  exit 1
fi

if ! command -v envsubst >/dev/null 2>&1; then
  echo "ERROR: envsubst is required to render templates."
  exit 1
fi

envsubst < ./prometheus/prometheus.yml.tpl > ./prometheus/prometheus.yml
envsubst < ./alertmanager/alertmanager.yml.tpl > ./alertmanager/alertmanager.yml

echo "Rendered prometheus and alertmanager configs with APP_HOST=${APP_HOST}."
