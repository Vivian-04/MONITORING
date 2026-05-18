# Runbook: LowDeploymentFrequency

## What is this alert?
No successful GitHub Actions deployments were recorded in the last 7 days.

## Likely causes
- The deployment workflow is broken.
- The team stopped shipping changes.
- GitHub token or exporter configuration is invalid.
- The exporter cannot reach the GitHub API.

## First 3 investigation steps
```bash
systemctl status github-actions-exporter --no-pager
journalctl -u github-actions-exporter -n 100 --no-pager
curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs?per_page=1
```

## How to resolve
- Fix exporter credentials if metrics are missing.
- Trigger a known-good deployment workflow.
- Review blocked pull requests or failing checks.
- Document delivery blockers in the team update.

## Should I roll back?
No. This is a delivery cadence alert, not a production incident.

## Escalation
Escalate to the CI/CD owner if no successful deployment happens within one business day.
