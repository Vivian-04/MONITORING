# Runbook: SloErrorBudgetExhausted

## What is this alert?
The 30-day availability SLO has fallen below 99.5%; the monthly error budget is consumed.

## Likely causes
- Repeated outages or sustained partial failure.
- Slow burn incidents were not resolved quickly enough.
- A recent deployment caused a long degradation.

## First 3 investigation steps
```bash
curl -vk http://$APP_HOST:8080/healthz
journalctl -u prometheus -u alertmanager -n 100 --no-pager
systemctl status prometheus alertmanager blackbox-exporter --no-pager
```

## How to resolve
- Stop risky deployments immediately.
- Review all open incidents and recent releases.
- Prioritize reliability fixes until the service is back within policy.

## Should I roll back?
Roll back any deployment linked to the budget exhaustion.

## Escalation
Escalate to the platform lead for feature freeze or reliability sprint decision.
