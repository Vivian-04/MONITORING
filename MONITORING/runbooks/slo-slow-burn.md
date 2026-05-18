# Runbook: SloBurnRateSlow / SloLatencyBurnRate

## What is this alert?
The service is burning error budget faster than planned, or p95 latency is above 500ms.

## Likely causes
- Partial application degradation.
- Increasing traffic or resource saturation.
- Slow downstream dependency.
- Recent deployment increased latency or error rate.

## First 3 investigation steps
```bash
curl -w '@-' -o /dev/null -s http://$APP_HOST:8080/healthz <<'EOF'
time_total=%{time_total}
http_code=%{http_code}
EOF
journalctl -u prometheus -u otel-collector -n 100 --no-pager
systemctl status prometheus blackbox-exporter otel-collector --no-pager
```

## How to resolve
- Identify the slow endpoint using the Unified Observability dashboard.
- Open Loki logs for the same time window and follow the trace ID into Tempo.
- Scale or fix the application component causing latency.
- Roll back if a recent deployment caused the regression.

## Should I roll back?
Roll back if the latency or burn began after deployment and no quick fix is clear.

## Escalation
Escalate to the app owner if slow burn lasts more than 30 minutes.
