#!/bin/bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: this script must be run as root or with sudo."
  exit 1
fi

INSTALL_DIR="$(pwd)"
SERVICE_USER=monitoring
GRAFANA_HOME="$INSTALL_DIR/grafana-home"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

if [ -z "${APP_HOST:-}" ]; then
  read -rp "Application server host or IP to monitor: " APP_HOST
fi
if [ -z "${APP_HOST:-}" ]; then
  echo "Application server host cannot be empty."
  exit 1
fi

if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
  read -rp "Slack webhook URL for Alertmanager notifications: " SLACK_WEBHOOK_URL
fi
if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
  echo "Slack webhook URL cannot be empty."
  exit 1
fi

if [ -z "${GITHUB_REPOSITORY:-}" ]; then
  read -rp "GitHub repository to monitor (owner/repo): " GITHUB_REPOSITORY
fi
if [ -z "${GITHUB_REPOSITORY:-}" ]; then
  echo "GitHub repository cannot be empty."
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  read -rsp "GitHub token for repository metrics (GITHUB_TOKEN): " GITHUB_TOKEN
  echo
fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "GitHub token cannot be empty."
  exit 1
fi

if [ -z "${GRAFANA_ADMIN_USER:-}" ]; then
  read -rp "Grafana admin user [admin]: " GRAFANA_ADMIN_USER
fi
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}

if [ -z "${GRAFANA_ADMIN_PASSWORD:-}" ]; then
  read -rp "Grafana admin password [admin]: " GRAFANA_ADMIN_PASSWORD
fi
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}

cat > .env <<EOF
APP_HOST=${APP_HOST}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
GITHUB_TOKEN=${GITHUB_TOKEN}
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
EOF

echo "Created .env with the monitoring target and Slack webhook."

apt update -y
apt install -y curl wget tar gzip unzip git python3 python3-venv gettext-base

id -u "$SERVICE_USER" >/dev/null 2>&1 || useradd --system --home-dir "$INSTALL_DIR" --shell /usr/sbin/nologin "$SERVICE_USER"

mkdir -p \
  "$INSTALL_DIR/bin" \
  "$INSTALL_DIR/prometheus/data" \
  "$INSTALL_DIR/prometheus/rules" \
  "$INSTALL_DIR/alertmanager/data" \
  "$INSTALL_DIR/grafana/data" \
  "$INSTALL_DIR/grafana/log" \
  "$INSTALL_DIR/grafana/conf" \
  "$INSTALL_DIR/grafana/plugins" \
  "$GRAFANA_HOME" \
  "$INSTALL_DIR/loki/data/chunks" \
  "$INSTALL_DIR/loki/data/rules" \
  "$INSTALL_DIR/loki/data/compactor" \
  "$INSTALL_DIR/tempo/data/generator/wal" \
  "$INSTALL_DIR/tempo/data/wal" \
  "$INSTALL_DIR/tempo/data/blocks" \
  "$INSTALL_DIR/blackbox" \
  "$INSTALL_DIR/github-actions-exporter"

chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR"

./render-configs.sh

cat > "$INSTALL_DIR/grafana/conf/grafana.ini" <<EOF
[paths]
data = $INSTALL_DIR/grafana/data
logs = $INSTALL_DIR/grafana/log
plugins = $INSTALL_DIR/grafana/plugins
provisioning = $INSTALL_DIR/grafana/provisioning

[server]
http_addr = 0.0.0.0
http_port = 3000

[security]
admin_user = $GRAFANA_ADMIN_USER
admin_password = $GRAFANA_ADMIN_PASSWORD
EOF

cat > "$INSTALL_DIR/blackbox/blackbox.yml" <<EOF
modules:
  http_2xx:
    prober: http
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      valid_status_codes: [200, 302]
      method: GET
      preferred_ip_protocol: ip4
EOF

function download_extract_tarball() {
  local url=$1
  local binary=$2
  local archive="/tmp/monitoring-$(basename "$url")"

  if [ ! -x "$INSTALL_DIR/bin/$binary" ]; then
    rm -rf /tmp/monitoring-release
    mkdir -p /tmp/monitoring-release
    curl -fsSL -o "$archive" "$url"
    tar -xzf "$archive" -C /tmp/monitoring-release
    local extracted=$(find /tmp/monitoring-release -type f -name "$binary" | head -n 1)
    if [ -z "$extracted" ]; then
      echo "ERROR: could not find $binary in $archive"
      exit 1
    fi
    mv "$extracted" "$INSTALL_DIR/bin/$binary"
    chmod +x "$INSTALL_DIR/bin/$binary"
  fi
}

function download_extract_grafana() {
  local url=$1
  local archive="/tmp/monitoring-grafana.tar.gz"

  if [ ! -x "$GRAFANA_HOME/bin/grafana-server" ]; then
    rm -rf /tmp/monitoring-release
    mkdir -p /tmp/monitoring-release
    curl -fsSL -o "$archive" "$url"
    tar -xzf "$archive" -C /tmp/monitoring-release
    rm -rf "$GRAFANA_HOME"
    mv /tmp/monitoring-release/grafana-* "$GRAFANA_HOME"
    mkdir -p "$INSTALL_DIR/grafana/data" "$INSTALL_DIR/grafana/log" "$INSTALL_DIR/grafana/plugins"
    chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR/grafana" "$GRAFANA_HOME"
  fi
}

function download_extract_loki() {
  local url=$1
  local archive="/tmp/monitoring-loki.zip"

  if [ ! -x "$INSTALL_DIR/bin/loki" ]; then
    rm -rf /tmp/monitoring-release
    mkdir -p /tmp/monitoring-release
    curl -fsSL -o "$archive" "$url"
    unzip -q "$archive" -d /tmp/monitoring-release
    mv /tmp/monitoring-release/loki-linux-amd64 "$INSTALL_DIR/bin/loki"
    chmod +x "$INSTALL_DIR/bin/loki"
  fi
}

function download_extract_zip() {
  local url=$1
  local pattern=$2
  local binary=$3
  local archive="/tmp/monitoring-$(basename "$url")"

  if [ ! -x "$INSTALL_DIR/bin/$binary" ]; then
    rm -rf /tmp/monitoring-release
    mkdir -p /tmp/monitoring-release
    curl -fsSL -o "$archive" "$url"
    unzip -q "$archive" -d /tmp/monitoring-release
    mv "/tmp/monitoring-release/$pattern" "$INSTALL_DIR/bin/$binary"
    chmod +x "$INSTALL_DIR/bin/$binary"
  fi
}

# Download the required binaries if missing

download_extract_tarball "https://github.com/prometheus/prometheus/releases/download/v2.55.1/prometheus-2.55.1.linux-amd64.tar.gz" "prometheus" "prometheus-2.55.1.linux-amd64"
download_extract_tarball "https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz" "alertmanager" "alertmanager-0.27.0.linux-amd64"

# Grafana uses a full home path

download_extract_grafana "https://dl.grafana.com/oss/release/grafana-10.1.3.linux-amd64.tar.gz"

download_extract_loki "https://github.com/grafana/loki/releases/download/v3.7.2/loki-linux-amd64.zip"

download_extract_tarball "https://github.com/grafana/tempo/releases/download/v1.8.0/tempo-1.8.0-linux-amd64.tar.gz" "tempo" "tempo-1.8.0.linux-amd64"
download_extract_tarball "https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz" "node_exporter" "node_exporter-1.7.0.linux-amd64"
download_extract_tarball "https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.24.0.linux-amd64.tar.gz" "blackbox_exporter" "blackbox_exporter-0.24.0.linux-amd64"
download_extract_tarball "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.92.0/otelcol-contrib_0.92.0_linux_amd64.tar.gz" "otelcol-contrib" "otelcol-contrib_0.92.0_linux_amd64"

# Make sure binary names are consistent
if [ -x "$INSTALL_DIR/bin/prometheus" ]; then
  true
fi
if [ -x "$INSTALL_DIR/bin/alertmanager" ]; then
  true
fi
if [ -x "$INSTALL_DIR/bin/tempo" ]; then
  true
fi
if [ -x "$INSTALL_DIR/bin/node_exporter" ]; then
  true
fi
if [ -x "$INSTALL_DIR/bin/blackbox_exporter" ]; then
  true
fi
if [ -x "$INSTALL_DIR/bin/otelcol-contrib" ]; then
  true
fi

# Install Python exporter environment
cd "$INSTALL_DIR/github-actions-exporter"
if [ ! -d venv ]; then
  python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# Install systemd units
cp "$INSTALL_DIR/systemd"/*.service /etc/systemd/system/
chmod 644 /etc/systemd/system/*.service
systemctl daemon-reload
systemctl enable --now prometheus alertmanager grafana loki tempo otel-collector node-exporter blackbox-exporter github-actions-exporter

echo "Systemd services enabled and started."

echo "Monitoring stack is running. Visit Grafana on port 3000."

echo
printf '%s\n' "Service status and listening ports:"
print_status() {
  local name=$1
  local port=$2
  local active
  active=$(systemctl is-active "$name" 2>/dev/null || true)
  if [ "$active" = "active" ]; then
    if [ -n "$port" ]; then
      printf '  %s: active (http://localhost:%s)\n' "$name" "$port"
    else
      printf '  %s: active\n' "$name"
    fi
  else
    printf '  %s: %s\n' "$name" "${active:-inactive}"
  fi
}

print_status prometheus 9090
print_status alertmanager 9093
print_status grafana 3000
print_status loki 3100
print_status tempo 3200
print_status otel-collector ""
print_status node-exporter 9100
print_status blackbox-exporter 9115
print_status github-actions-exporter 9117
