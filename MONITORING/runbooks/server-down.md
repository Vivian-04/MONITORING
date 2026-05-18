# Runbook: ServerDown

## What is this alert?
Blackbox Exporter cannot reach the configured application host for more than 2 minutes.

## Likely causes
- The application server or web service is down.
- The monitoring server cannot reach the application network.
- A firewall/security-group rule blocks the monitoring server.
- The app host IP supplied during setup is wrong.

## First 3 investigation steps
```bash
curl -vk http://$APP_HOST:8080/healthz
curl -vk http://$APP_HOST:8080/
systemctl status blackbox-exporter prometheus --no-pager
```

## How to resolve
- Confirm the correct app host is in `/opt/monitoring/.env`.
- Fix firewall rules so the monitoring server can reach the app server.
- Restart app-side services if the application is actually down.
- Rerun `/opt/monitoring/render-configs.sh` and restart Prometheus if the app host changed.

## Should I roll back?
Roll back the application only if the outage began after an application deployment.

## Escalation
Escalate immediately to the application owner and platform lead.
