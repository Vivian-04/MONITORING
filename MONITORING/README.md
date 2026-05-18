# Production Observability Stack - Stage 6

This repository provisions a separate monitoring server for a running application server. The application remains on its own host. The monitoring server is bootstrapped with native Linux binaries and systemd units only. Docker is not installed or required for the monitoring stack.

## One-command deployment

Run this from the application server checkout:

```bash
cd APP/terraform
terraform init
terraform apply
```

Terraform will ask for:

- `monitoring_host`: IP or hostname of the monitoring server
- `ssh_user`: SSH user for the monitoring server, default `root`
- `app_host`: IP or hostname of the existing application server
- `slack_webhook_url`: Slack webhook for `#DevOps-Alerts`
- `github_repository`: repository to collect GitHub Actions metrics from, in `owner/repo` format
- `github_token`: token for GitHub Actions metrics
- Grafana admin credentials

You can also run the bootstrap directly:

```bash
cd APP
./deploy-monitoring-ssh.sh
```

## Architecture

The monitoring server runs these systemd services:

- Prometheus on `:9090` for metrics and alert rules
- Alertmanager on `:9093` for routing, inhibition, and Slack notifications
- Grafana on `:3000` for dashboards
- Loki on `:3100` for logs
- Tempo on `:3200` for traces
- OpenTelemetry Collector on `:4317` and `:4318` for OTLP traces and logs
- Node Exporter on `:9100` for host metrics
- Blackbox Exporter on `:9115` for HTTP and TLS probes
- GitHub Actions Exporter on `:9117` for DORA and CI/CD metrics

The application sends traces to:

```text
http://<MONITORING_SERVER_IP>:4318
```

The monitoring server probes the application host supplied during deployment:

```text
http://<APP_HOST>:8080/
http://<APP_HOST>:8080/healthz
https://<APP_HOST>/
```

## Version-controlled configuration

- Prometheus config: `prometheus/prometheus.yml.tpl`
- Alertmanager config: `alertmanager/alertmanager.yml.tpl`
- Slack template: `alertmanager/templates/slack.tmpl`
- Alert and recording rules: `prometheus/rules/*.yml`
- Grafana datasources: `grafana/provisioning/datasources/datasources.yml`
- Grafana dashboard provisioning: `grafana/provisioning/dashboards/dashboards.yml`
- Dashboard JSON: `grafana/dashboards/*.json`
- Loki config: `loki/loki-config.yml`
- Tempo config: `tempo/tempo-config.yml`
- OpenTelemetry Collector config: `otel-collector/otel-config.yml`
- systemd units: `systemd/*.service`
- Runbooks: `runbooks/*.md`
- Reliability docs: `docs/*.md`

## Retention

- Prometheus metrics: 30 days, set in `systemd/prometheus.service`
- Loki logs: 744 hours, set in `loki/loki-config.yml`
- Tempo traces: 720 hours, set in `tempo/tempo-config.yml`

## Dashboards

All dashboards are provisioned as JSON files and loaded automatically by Grafana.

- DORA Metrics: deployment frequency, lead time, change failure rate, MTTR, and benchmark classification
- SLO and Error Budget: SLI vs SLO, budget remaining, burn rate, and compliance history
- Node Exporter: CPU, memory, disk, network, and system load
- Blackbox Exporter: uptime, response time, SSL expiry, and probe success
- Unified Observability: golden signals, Loki logs, and Tempo trace search

Loki derived fields are configured so `traceID` values in logs open directly in Tempo.

## Alerting

All alert rules live in `prometheus/rules/*.yml`; no Grafana UI alerts are required.

Infrastructure alerts:

- CPU warning at 80% for 5 minutes
- CPU critical at 90% for 10 minutes
- Memory warning at 80%
- Memory critical at 90%
- Disk warning at 75%
- Disk critical at 90%
- Server down after 2 minutes of failed probes

SLO alerts:

- Fast burn: 14.4x burn rate, critical
- Slow burn: 5x burn rate, warning
- Error budget exhausted
- Latency SLO breach

DORA alerts:

- High change failure rate
- High mean time to restore
- Slow workflow execution
- Low deployment frequency

Alertmanager groups alerts by service and severity, inhibits noisy resource alerts when `ServerDown` is firing, and sends structured Slack messages to `#DevOps-Alerts` with alert name, severity, affected host, current value, dashboard link, runbook link, and firing/resolved status.

## Error Budget Policy

The primary availability SLO is 99.5% over 30 days. The monthly error budget is:

```text
(1 - 0.995) * 30 days = 216 minutes
```

- 0-50% consumed: normal delivery continues.
- 50-100% consumed: review active incidents, prioritize reliability fixes, and avoid risky deploys.
- 100% consumed: feature freeze or reliability sprint until the service returns to SLO.

The platform lead owns the final decision. SLOs are reviewed weekly during the task window and monthly in normal operation.

## Game Day evidence to capture

Scenario 1: deployment failure

1. Trigger a failing GitHub Actions workflow.
2. Capture the failed workflow.
3. Capture DORA dashboard CFR change.
4. Capture `HighChangeFailureRate` Slack alert.
5. Capture recovery after a successful run.

Scenario 2: latency injection

1. Add artificial latency on the application server.
2. Capture Blackbox latency rising.
3. Capture SLO burn increase.
4. Capture fast/slow burn Slack alert.
5. Capture logs in Loki and trace in Tempo for the same time window.
6. Remove latency and capture resolved notification.

Scenario 3: resource pressure

1. Run CPU or memory pressure on the monitored application or monitoring host.
2. Capture warning alert first.
3. Continue pressure until critical alert.
4. Stop pressure.
5. Capture resolved notification.

## Evidence checklist

- `systemctl status` showing all LGTM services active
- Grafana datasource provisioning screen
- SLO and Error Budget dashboard
- DORA dashboard with classification
- Node Exporter dashboard
- Blackbox dashboard with SSL expiry
- Unified Observability dashboard with metric, log, and trace drill-down
- Prometheus alert rules from version-controlled YAML
- Alertmanager routing and inhibition config
- Firing and resolved Slack alert in `#DevOps-Alerts`
- Game Day screenshots for trigger, degradation, alert, trace, and recovery

## Troubleshooting commands

```bash
sudo systemctl status prometheus alertmanager grafana loki tempo otel-collector node-exporter blackbox-exporter github-actions-exporter --no-pager
sudo journalctl -u prometheus -u alertmanager -u grafana -n 100 --no-pager
curl http://localhost:9090/-/ready
curl http://localhost:3100/ready
curl http://localhost:3200/ready
curl http://localhost:9115/metrics
curl http://localhost:9117/metrics
```
