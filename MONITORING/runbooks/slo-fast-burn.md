# Runbook: SloBurnRateFast

## What is this alert?
We are consuming our error budget 14.4x faster than normal.
At this rate the entire 30-day error budget will be exhausted in approximately 2 hours.

## What is the error budget?
Our availability SLO is 99.5%. The error budget is 0.5% of 30 days = 3.6 hours.
Fast burn means we are using that 3.6 hours at 14.4x normal speed.

## Likely Causes
- Server is completely down (check ServerDown alert)
- Nginx is returning errors to all requests
- A deployment broke the platform

## First 3 Investigation Steps

### Step 1 — Check what is failing
```bash
curl -v http://localhost/
curl -v http://localhost/nginx-health
docker ps
```

### Step 2 — Check Prometheus for the exact error rate
Go to http://EC2-IP:9090 and query:
1 - probe_success{job="blackbox-http"}

### Step 3 — Check recent deployments
```bash
git -C ~/devops-sandbox log --oneline -5
docker logs sandbox-nginx --tail 50
```

## How to Resolve
1. Identify and fix the root cause of failures
2. If a deployment caused it: `git revert HEAD && make up`
3. If Nginx is down: `docker restart sandbox-nginx`

## Should I Roll Back?
Yes — if this started after a deployment, roll back immediately.
Every minute at this burn rate costs error budget.

## Escalation
Escalate IMMEDIATELY. This alert means we will breach our SLO within hours.
