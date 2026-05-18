# Runbook: HighCpuWarning

## What is this alert?
CPU usage on the monitoring server is above 80% for at least 5 minutes.

## Likely causes
- Prometheus, Loki, Tempo, or Grafana is under query load.
- A systemd service is looping or restarting.
- A Game Day CPU pressure test is running.
- The host is undersized for the current retention/query volume.

## First 3 investigation steps
```bash
top -b -n 1 | head -20
ps aux --sort=-%cpu | head -10
systemctl --failed
```

## How to resolve
- Stop any known Game Day load test.
- Restart only the noisy service after checking logs: `sudo systemctl restart <service>`.
- Reduce expensive dashboard queries or Prometheus query ranges.
- If sustained, resize the monitoring server.

## Should I roll back?
Only roll back if the spike started immediately after a monitoring stack change.

## Escalation
Escalate to the platform lead if CPU remains above 80% for 30 minutes.
