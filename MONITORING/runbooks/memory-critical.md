# Runbook: HighMemoryCritical

## What is this alert?
Memory usage has exceeded 90%. The system is critically low on RAM.
OOM (Out of Memory) killer may start terminating processes.

## Likely Causes
- System is running out of RAM completely
- OOM killer has already killed some processes
- Swap is not configured — no safety net

## First 3 Investigation Steps

### Step 1 — Check if OOM killer fired
```bash
dmesg | grep -i "out of memory" | tail -10
journalctl -k | grep -i "oom" | tail -10
```

### Step 2 — Emergency memory recovery
```bash
# Stop all sandbox environments immediately
cd ~/devops-sandbox && make down

# Free Docker resources
docker system prune -f
```

### Step 3 — Check what survived
```bash
docker ps
free -h
```

## How to Resolve
1. Stop all non-essential containers immediately
2. Run `make down` on Stage 5
3. Restart observability stack: `terraform apply -auto-approve`

## Should I Roll Back?
If a recent deployment caused this — yes, roll back immediately.

## Escalation
This is a critical situation. Escalate immediately to team lead.
