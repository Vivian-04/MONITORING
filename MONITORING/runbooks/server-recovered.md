# Runbook: ServerRecovered

## What is this alert?
Blackbox Exporter can reach the application again after a previous outage.

## Likely causes
- The application service recovered.
- A network or firewall issue was fixed.
- A bad deployment was rolled back.

## First 3 investigation steps
```bash
curl -vk http://$APP_HOST:8080/healthz
systemctl status prometheus blackbox-exporter --no-pager
grep APP_HOST /opt/monitoring/.env
```

## How to resolve
- No active fix is required if probes remain healthy.
- Confirm the related `ServerDown` alert resolved in Slack.
- Record the recovery time in the incident timeline.

## Should I roll back?
No. This is a recovery notification.

## Escalation
Close the incident only after the app owner confirms user-facing recovery.
