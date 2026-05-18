# Runbook: SloLatencyBurnRate

## What is this alert?
The p95 HTTP probe latency is above 500ms for at least 5 minutes.

## Likely causes
- Application code path is slow.
- Host CPU, memory, disk, or network saturation.
- Downstream dependency is slow.
- Recent deployment introduced a performance regression.

## First 3 investigation steps
```bash
curl -w 'code=%{http_code} total=%{time_total}\n' -o /dev/null -s http://$APP_HOST:8080/healthz
systemctl status otel-collector prometheus blackbox-exporter --no-pager
journalctl -u otel-collector -u prometheus -n 100 --no-pager
```

## How to resolve
- Use the Unified Observability dashboard to correlate the latency spike with logs and traces.
- Identify the endpoint or service span responsible in Tempo.
- Roll back or optimize the slow path.
- Scale the application host if saturation is the cause.

## Should I roll back?
Roll back if the latency began after a deployment and cannot be fixed quickly.

## Escalation
Escalate to the application owner if latency remains above target for 30 minutes.
