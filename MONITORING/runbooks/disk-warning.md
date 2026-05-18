# Runbook: HighDiskWarning

## What is this alert?
Disk usage on the monitoring server is above 75%.

## Likely causes
- Prometheus TSDB, Loki chunks, or Tempo blocks are growing.
- Journal logs are accumulating.
- Old release archives remain in `/tmp`.

## First 3 investigation steps
```bash
df -h
sudo du -sh /opt/monitoring/* /var/log/journal /tmp 2>/dev/null | sort -rh
journalctl --disk-usage
```

## How to resolve
- Remove old temporary archives from `/tmp`.
- Vacuum journal logs: `sudo journalctl --vacuum-time=7d`.
- Verify retention is set: Prometheus 30d, Loki 744h, Tempo 720h.
- Increase disk size if retention requirements exceed capacity.

## Should I roll back?
No, unless disk growth started after a retention/config change.

## Escalation
Escalate if usage continues rising or reaches the critical 90% threshold.
