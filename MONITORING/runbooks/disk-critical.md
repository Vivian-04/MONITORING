# Runbook: HighDiskCritical

## What is this alert?
Disk usage has exceeded 90%. The system is critically low on disk space.
Services will start failing to write data — Prometheus, Loki, application logs.

## Likely Causes
- Log files not rotating
- Docker images and layers accumulating
- Prometheus retention not working correctly

## First 3 Investigation Steps

### Step 1 — Emergency space recovery
```bash
# Immediate cleanup
docker system prune -a -f --volumes
```

### Step 2 — Find largest directories
```bash
du -sh /* 2>/dev/null | sort -rh | head -20
```

### Step 3 — Clean logs
```bash
rm -rf ~/devops-sandbox/logs/archived/*
find ~/devops-sandbox/logs -name "*.log" -size +100M -delete
```

## How to Resolve
1. Run `docker system prune -a -f` immediately
2. Delete old archived logs
3. Consider increasing EC2 volume size in AWS console

## Should I Roll Back?
Not applicable — disk issues are infrastructure, not deployment related.

## Escalation
Escalate immediately. At 95%+ disk, the entire platform will fail.
