# Runbook: HighCpuCritical

## What is this alert?
CPU usage on the monitoring server is above 90% for at least 10 minutes.

## Likely causes
- A service is stuck in a hot loop.
- Very expensive Prometheus/Grafana queries are running.
- Loki or Tempo compaction is consuming CPU.
- Resource pressure was intentionally injected for Game Day.

## First 3 investigation steps
```bash
top -b -n 1 | head -20
ps aux --sort=-%cpu | head -10
journalctl -p warning..alert -n 100 --no-pager
```

## How to resolve
- Stop the highest CPU non-critical process if it is clearly runaway.
- Restart the affected service with `sudo systemctl restart <service>`.
- Temporarily reduce dashboard refresh rates or query windows.
- Add CPU capacity if the load is legitimate.

## Should I roll back?
Yes, if the critical spike began after a config or binary version change.

## Escalation
Escalate immediately if CPU remains above 90% for 15 minutes.
