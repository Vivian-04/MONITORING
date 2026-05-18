# Runbook: HighCpuCritical

## What is this alert?
CPU usage has exceeded 90% for more than 10 minutes. This is critical.
The system is severely overloaded. Response times will be degraded.

## Likely Causes
- Multiple sandbox environments under heavy load simultaneously
- A container in an infinite loop
- Memory pressure causing excessive swapping and CPU thrashing
- A DoS attack or traffic flood

## First 3 Investigation Steps

### Step 1 — Immediate check
```bash
top -b -n 1 | head -20
docker stats --no-stream
```

### Step 2 — Find and kill the offender
```bash
# Find the highest CPU process
ps aux --sort=-%cpu | head -5

# If it is a Docker container
docker stats --no-stream | sort -k3 -rh | head -5
```

### Step 3 — Check memory pressure
```bash
free -h
vmstat 1 5
```

## How to Resolve
1. Kill the highest CPU consuming container: `docker stop <container>`
2. If unknown process: `kill -9 <PID>`
3. If all containers are high: `make down` on Stage 5 to free resources

## Should I Roll Back?
Yes — if this started after a deployment, roll back immediately.

## Escalation
Escalate immediately if CPU stays above 90% for more than 15 minutes.
