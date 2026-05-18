# Runbook: HighMemoryWarning

## What is this alert?
Memory usage has exceeded 80% for more than 5 minutes.
Available RAM is getting low. System may start swapping soon.

## Likely Causes
- Too many sandbox environments running simultaneously
- A memory leak in the Flask demo app
- Loki or Tempo retaining too much data in memory
- Log files growing too large and being read into memory

## First 3 Investigation Steps

### Step 1 — Check memory usage
```bash
free -h
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Cached"
```

### Step 2 — Find memory-heavy containers
```bash
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

### Step 3 — Check for memory leaks
```bash
# Check if memory is growing over time
watch -n 5 free -h
```

## How to Resolve
- Destroy idle sandbox environments: `make destroy ENV=<id>`
- Restart memory-heavy containers: `docker restart loki` or `docker restart tempo`
- Clear Docker build cache: `docker system prune -f`

## Should I Roll Back?
Only if memory spike started after a deployment.

## Escalation
Escalate if memory stays above 80% after destroying all sandbox environments.
