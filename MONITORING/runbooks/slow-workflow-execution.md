# Runbook: SlowWorkflowExecution

## What is this alert?
The p95 GitHub Actions workflow duration is above 1 hour.

## Likely causes
- Slow dependency install or build steps.
- Queueing delays in GitHub Actions runners.
- Tests are flaky or retrying.
- Deployment confirmation takes too long.

## First 3 investigation steps
```bash
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs?per_page=5
systemctl status github-actions-exporter --no-pager
journalctl -u github-actions-exporter -n 100 --no-pager
```

## How to resolve
- Inspect the slowest workflow runs in GitHub Actions.
- Cache dependencies and remove redundant build steps.
- Split long tests or move non-blocking checks out of the deploy path.
- Document manual deployment confirmation time in the PIR if humans are the bottleneck.

## Should I roll back?
No. This is a delivery-performance alert, not a production correctness alert.

## Escalation
Escalate to the CI/CD owner if p95 remains above 1 hour for a day.
