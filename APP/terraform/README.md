# Monitoring Server Deployment Module

This module deploys the monitoring stack by executing the SSH-based app server deployment script.

## How it works

1. The app server runs `terraform apply` from `APP/terraform`.
2. Terraform executes `../deploy-monitoring-ssh.sh` using a local provisioner.
3. The deploy script connects to the monitoring server over SSH.
4. The monitoring server installs git, Python, and other native prerequisites.
5. The monitoring server clones the `MONITORING` repository into `/opt/monitoring`.
6. `setup-monitoring.sh` renders configs, downloads native binaries, installs systemd unit files, and starts the monitoring services.
7. Systemd manages Prometheus, Alertmanager, Grafana, Loki, Tempo, OpenTelemetry Collector, Node Exporter, Blackbox Exporter, and the GitHub Actions exporter.

## Required inputs

- `app_host`: IP or hostname of the application server.
- `slack_webhook_url`: Slack webhook for Alertmanager notifications.
- `grafana_admin_user`: Grafana admin username.
- `grafana_admin_password`: Grafana admin password.

## Repository and GitHub settings

- The deployment script checks out the monitoring code from the repository configured in `APP/deploy-monitoring-ssh.sh`:
  - `REMOTE_REPO=https://github.com/Vivian-04/MONITORING.git`
- The `GITHUB_REPOSITORY` prompted by the script is a separate value used by the GitHub Actions exporter, and should be the owner/repo of the repository whose workflow metrics you want to collect.

## Command sequence

### Option 1: Run terraform apply on the app server (SSH-based deploy)

```bash
cd /home/hngdevops/APP/terraform
chmod +x ../deploy-monitoring-ssh.sh
terraform init
terraform apply
```

This runs the SSH deployment script from Terraform and performs the full remote bootstrap.
The remote monitoring host is configured to run the stack under systemd, not Docker.
It will prompt for:
- monitoring server IP/hostname
- SSH user
- application server host/IP
- Slack webhook URL
- optional Grafana admin username/password

### Option 2: Run the deploy script directly

```bash
cd /home/hngdevops/APP
chmod +x deploy-monitoring-ssh.sh
./deploy-monitoring-ssh.sh
```

This performs the same SSH-based remote deployment without using Terraform.

## Remote monitoring server bootstrap

`deploy-monitoring-ssh.sh` already runs `setup-monitoring.sh` on the remote monitoring host.
That script installs native binaries, renders config, writes systemd units, and starts the stack.

If you need to rerun the bootstrap manually for troubleshooting, SSH into the monitoring host as a root user or a sudo-capable user and run:

```bash
ssh root@<MONITORING_SERVER_IP>
cd /opt/monitoring
chmod +x setup-monitoring.sh
./setup-monitoring.sh
```

If you connect as a non-root user, ensure the account has passwordless sudo privileges on the monitoring host.

The monitoring bootstrap script prompts for:
- application server host/IP
- Slack webhook URL
- optional Grafana admin credentials

## App server deployment process

From the application server, the launched monitoring server becomes a separate host.
The monitoring instance uses the supplied `app_host` to probe the app and collect traces.

The deployed stack runs under `systemd` on the monitoring host, not Docker Compose.

If you want to use GitHub Actions to validate Terraform, trigger the workflow in `.github/workflows/monitoring-deploy.yml`.
