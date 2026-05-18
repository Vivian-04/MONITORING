# Runbook: HighMemoryCritical

## What is this alert?
Memory usage on the monitoring server is above 90%. The host may start swapping or killing processes.

## Likely causes
- A runaway query or ingestion spike.
- A service memory leak.
- The monitoring server is undersized.
- Game Day memory pressure simulation.

## First 3 investigation steps
```bash
free -h
vmstat 1 5
ps aux --sort=-%mem | head -10
```

## How to resolve
- Stop any intentional pressure test.
- Restart the largest leaking service after saving logs.
- Temporarily reduce query load.
- Resize the monitoring server if memory pressure is sustained.

## Should I roll back?
Yes, if the critical memory usage started after a deployment or config change.

## Escalation
Escalate immediately if swap grows or services begin failing.
