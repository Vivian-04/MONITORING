# Runbook: HighDiskWarning

## What is this alert?
Disk usage has exceeded 75% on one or more filesystems.

## Likely Causes
- Log files growing too large (Stage 5 app logs)
- Docker images accumulating
- Prometheus or Loki data exceeding expected size
- Old archived environment logs not cleaned up

## First 3 Investigation Steps

### Step 1 — Find what is using disk
```bash
df -h
du -sh /* 2>/dev/null | sort -rh | head -10
```

### Step 2 — Check Docker disk usage
```bash
docker system df
docker system df -v
```

### Step 3 — Check log sizes
```bash
du -sh ~/devops-sandbox/logs/
du -sh ~/devops-sandbox/logs/archived/
```

## How to Resolve
- Clean Docker: `docker system prune -a -f`
- Clean old logs: `rm -rf ~/devops-sandbox/logs/archived/*`
- Clean old Stage 5 environments: `cd ~/devops-sandbox && make clean`

## Should I Roll Back?
No — this is not deployment related.

## Escalation
If disk hits 90%, escalate immediately — system will fail to write logs and metrics.
