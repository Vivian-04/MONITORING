# Toil and Automation

## Toil 1: Manual monitoring server bootstrap

Manual work:

- SSH into the monitoring server.
- Install packages.
- Download observability binaries.
- Write configs.
- Start services.

Automation implemented:

- `APP/terraform` asks for monitoring host, app host, Slack webhook, and GitHub metrics inputs.
- `deploy-monitoring-ssh.sh` connects to the monitoring server.
- `setup-monitoring.sh` installs native binaries, renders configs, writes systemd units, and starts services.

Impact:

- Repeatable one-command deployment.
- Monitoring server can be recreated or destroyed without hand configuration.

## Toil 2: Manual dashboard and alert setup

Manual work:

- Creating Grafana dashboards through the UI.
- Adding datasources by hand.
- Creating UI alerts manually.

Automation implemented:

- Grafana datasources are provisioned in YAML.
- Dashboards are committed as JSON.
- Alert rules are Prometheus YAML files.
- Alertmanager routing and Slack message templates are version controlled.

Impact:

- Dashboards and alerts are reproducible.
- Reviews can happen in GitHub.
- A fresh monitoring server gets the same observability behavior.

## Toil 3: Manual CI/CD metrics calculation

Manual work:

- Checking GitHub Actions history by hand.
- Manually estimating deployment frequency and change failure rate.

Automation implemented:

- `github-actions-exporter` scrapes GitHub Actions workflow runs.
- Prometheus recording rules calculate DORA metrics.
- Grafana dashboard displays DORA classification.

Impact:

- Engineering performance is visible continuously.
- CFR and MTTR alerts fire when delivery quality degrades.
