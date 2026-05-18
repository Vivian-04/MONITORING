# Monitoring Stack

This directory contains a fully provisioned LGTM observability stack for the monitoring server.

## How to run

1. SSH into the monitoring server:

```bash
ssh ubuntu@<MONITORING_SERVER_IP>
```

2. Start the interactive setup script:

```bash
cd /opt/monitoring
chmod +x setup-monitoring.sh
./setup-monitoring.sh
```

Alternatively, from the application server you can deploy directly to the monitoring server with no AWS credentials by running:

```bash
cd /home/hngdevops
chmod +x deploy-monitoring-ssh.sh
./deploy-monitoring-ssh.sh
```

That script will prompt for the monitoring server host, SSH user, app host, Slack webhook, and Grafana credentials.

3. Enter the requested values when prompted:
   - application server IP or hostname to monitor
   - Slack webhook URL for Alertmanager
   - GitHub repository to monitor (owner/repo)
   - GitHub token for GitHub Actions metrics collection
   - Grafana admin username (default: `admin`)
   - Grafana admin password (default: `admin`)

4. The script will generate `.env`, render Prometheus and Alertmanager configs, and start the stack.

If you prefer non-interactive setup, create a `.env` file from `.env.example` and then run:

```bash
cd /opt/monitoring
./render-configs.sh
docker compose up -d
```

## What is included

- Prometheus
- Alertmanager
- Grafana with dashboards provisioned in code
- Loki
- Tempo
- OpenTelemetry Collector
- Node Exporter
- Blackbox Exporter
- GitHub Actions metrics exporter for CI/CD and DORA telemetry
- System journal logs ingested through OpenTelemetry Collector

## Notes

- `render-configs.sh` renders the Prometheus and Alertmanager templates using `.env`.
- `docker compose` mounts all config folders and loads the dashboards automatically.
- This stack is designed to run on a separate monitoring server from the application server.
