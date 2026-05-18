# Runbook: ServerDown

## What is this alert?
The Blackbox Exporter HTTP probe has been failing for more than 2 minutes.
One or more of the monitored endpoints is unreachable or returning errors.

## Likely Causes
- Nginx container has crashed or stopped
- The Stage 5 platform is down
- The EC2 instance has a networking issue
- A firewall rule is blocking traffic

## First 3 Investigation Steps

### Step 1 — Check which endpoint is down
```bash
curl -v http://localhost/
curl -v http://localhost:8080/health
curl -v http://localhost/nginx-health
```

### Step 2 — Check Nginx status
```bash
docker ps | grep nginx
docker logs sandbox-nginx --tail 50
```

### Step 3 — Check Stage 5 platform
```bash
cd ~/devops-sandbox && make status
docker ps
```

## How to Resolve
- If Nginx is down: `docker restart sandbox-nginx`
- If Stage 5 is down: `cd ~/devops-sandbox && make up`
- If network issue: `sudo systemctl restart networking`

## Should I Roll Back?
Yes — if this started after a deployment, roll back immediately.

## Escalation
Escalate immediately — this means the platform is completely down for users.
