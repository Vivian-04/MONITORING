# Runbook: SloBurnRateFast

## What is this alert?
The service is burning the 99.5% availability error budget at 14.4x or faster.

## Likely causes
- The application is down or returning errors.
- Latency is high enough that probes fail.
- A bad deployment created a broad outage.
- Network connectivity between the monitoring and app server is broken.

## First 3 investigation steps
```bash
curl -vk http://$APP_HOST:8080/healthz
curl -vk http://$APP_HOST:8080/
journalctl -u prometheus -u blackbox-exporter -n 100 --no-pager
```

## How to resolve
- Fix the application or network path causing failed probes.
- If a deployment caused the burn, roll back immediately.
- Confirm recovery in Grafana's SLO dashboard and wait for resolved Slack notification.

## Should I roll back?
Yes, if the burn started after a deployment. Every minute consumes error budget.

## Escalation
Escalate immediately. Fast burn can exhaust the monthly budget in hours.
