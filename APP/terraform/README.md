# Terraform Deployment for the Monitoring Server

This module bootstraps a separate monitoring server over SSH. The application remains on its current server. The monitoring stack runs as native systemd services; Docker is not installed or used for the monitoring server.

## One-command deployment

```bash
cd APP/terraform
terraform init
terraform apply
```

Terraform prompts for:

- `monitoring_host`: monitoring server IP or hostname
- `ssh_user`: SSH user for the monitoring server, default `root`
- `app_host`: existing application server IP or hostname
- `slack_webhook_url`: Slack webhook for `#DevOps-Alerts`
- `github_repository`: repository for GitHub Actions/DORA metrics, in `owner/repo` format
- `github_token`: GitHub token used by the metrics exporter
- `grafana_admin_user`
- `grafana_admin_password`

## Example tfvars

```hcl
monitoring_host = "10.0.0.10"
ssh_user = "ubuntu"
app_host = "10.0.0.5"
slack_webhook_url = "https://hooks.slack.com/services/..."
github_repository = "Vivian-04/MONITORING"
github_token = "ghp_replace_me"
grafana_admin_user = "admin"
grafana_admin_password = "admin"
```

Then run:

```bash
terraform apply -var-file=terraform.tfvars
```

## What Terraform does

The `null_resource.deploy_monitoring` resource runs `../deploy-monitoring-ssh.sh` with Terraform-provided values. The script:

1. Connects to the monitoring server over SSH.
2. Installs native prerequisites.
3. Clones this repository.
4. Copies `MONITORING/` into `/opt/monitoring`.
5. Writes `/opt/monitoring/.env`.
6. Runs `setup-monitoring.sh`.

`setup-monitoring.sh` downloads native binaries, renders templates, installs systemd unit files, enables services, and starts:

- Prometheus
- Alertmanager
- Grafana
- Loki
- Tempo
- OpenTelemetry Collector
- Node Exporter
- Blackbox Exporter
- GitHub Actions Exporter

## Direct script fallback

```bash
cd APP
./deploy-monitoring-ssh.sh
```

When run directly, the script asks for the same inputs interactively.
