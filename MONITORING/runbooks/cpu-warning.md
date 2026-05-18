# Runbook: HighCpuWarning

## What is this alert?
CPU usage has exceeded 80% for more than 5 minutes on the EC2 instance.
This is a warning — the system is under stress but still functional.

## Likely Causes
- High traffic spike to sandbox environments
- A runaway process or container consuming CPU
- A cron job or scheduled task running
- stress-ng running from a Game Day test

## First 3 Investigation Steps

### Step 1 — Identify what is consuming CPU
```bash
top -b -n 1 | head -20
docker stats --no-stream
```

### Step 2 — Check which containers are busy
```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Step 3 — Check for runaway processes
```bash
ps aux --sort=-%cpu | head -10
```

## How to Resolve
- If a specific container is using too much CPU: `docker restart <container>`
- If it is a cron job: wait for it to complete
- If traffic spike: check if it normalises naturally

## Should I Roll Back?
Only if the CPU spike started immediately after a deployment.

## Escalation
If CPU stays above 80% for more than 30 minutes with no clear cause, escalate to team lead.
