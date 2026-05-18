# Runbook: HighMemoryWarning

## What is this alert?
Memory usage on the monitoring server is above 80% for at least 5 minutes.

## Likely causes
- Large Grafana, Prometheus, Loki, or Tempo queries.
- Loki/Tempo ingestion spike.
- A service memory leak.
- Game Day memory pressure simulation.

## First 3 investigation steps
```bash
free -h
ps aux --sort=-%mem | head -10
systemctl status prometheus loki tempo grafana --no-pager
```

## How to resolve
- Stop known memory pressure tests.
- Reduce query windows and dashboard refresh rates.
- Restart the leaking service after checking `journalctl -u <service>`.
- Increase memory if sustained load is legitimate.

## Should I roll back?
Only if the memory growth began after a monitoring config or version change.

## Escalation
Escalate if memory remains above 80% for 30 minutes or swap begins growing.
