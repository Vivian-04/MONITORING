# Runbook: HighDiskCritical

## What is this alert?
Disk usage on the monitoring server is above 90%. Metrics, logs, and traces may stop writing soon.

## Likely causes
- Retention directories grew faster than expected.
- A service is writing excessive logs.
- A Game Day or incident generated unusually high telemetry.

## First 3 investigation steps
```bash
df -h
sudo du -xh /opt/monitoring /var/log /tmp 2>/dev/null | sort -rh | head -20
sudo journalctl --disk-usage
```

## How to resolve
- Remove nonessential files in `/tmp`.
- Vacuum logs: `sudo journalctl --vacuum-time=3d`.
- Restart a service only if it is writing runaway logs.
- Increase disk size before restarting the full stack if data must be preserved.

## Should I roll back?
Only if a recent retention or logging change caused the growth.

## Escalation
Escalate immediately. At 90%, the observability platform can lose data.
