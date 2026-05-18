# Runbook: HighChangeFailureRate

## What is this alert?
More than 15% of deployments in the last 24 hours have failed.
The DORA Elite benchmark is less than 5% failure rate.

## Likely Causes
- Tests are not catching bugs before deployment
- Deployment scripts have errors
- Infrastructure issues causing deployments to fail
- Missing environment variables or secrets

## First 3 Investigation Steps

### Step 1 — Check recent GitHub Actions runs
Go to https://github.com/Vivian-04/devops-sandbox/actions
Look at recent workflow runs — which ones failed and why?

### Step 2 — Check the failure logs
Click on the failed workflow run in GitHub Actions.
Look at which step failed and the error message.

### Step 3 — Check if it is a recurring pattern
Is the same step always failing?
Is it failing on specific types of changes?

## How to Resolve
1. Fix the root cause of the failing step
2. Add better tests to catch the issue before deployment
3. Consider adding a smoke test after deployment

## Should I Roll Back?
The failed deployments already failed — nothing to roll back.
Focus on fixing forward.

## Escalation
Escalate if CFR stays above 15% for more than 24 hours.
