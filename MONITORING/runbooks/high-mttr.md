# Runbook: HighMeanTimeToRestore

## What is this alert?
The average time to resolve incidents is exceeding 1 hour.
The DORA Elite benchmark is less than 1 hour MTTR.

## Likely Causes
- Alerts are firing but not being noticed
- Investigation is taking too long due to poor observability
- Recovery procedures are not documented or automated
- On-call engineer is not available

## First 3 Investigation Steps

### Step 1 — Check active alerts
Go to http://EC2-IP:9093 (Alertmanager)
How many alerts are currently firing?
How long have they been firing?

### Step 2 — Check if alerts are reaching Slack
Check the #devops-alerts Slack channel.
Are firing alerts appearing? Are resolved alerts appearing?

### Step 3 — Review runbooks
Are the runbooks clear enough to follow?
Is the investigation process taking too long?

## How to Resolve
1. Acknowledge the active alert and start investigation
2. Follow the runbook for the specific alert that is firing
3. After resolution — document what slowed down the process

## Should I Roll Back?
Depends on the underlying alert. Check the runbook for that specific alert.

## Escalation
If MTTR is consistently above 1 hour, this indicates a process problem.
Schedule a team retrospective to improve incident response.
