# Game Day Plan and Evidence Log

## Scenario 1: Deployment Failure

Goal: prove that CI/CD failure affects DORA metrics and produces an actionable alert.

Steps:

1. Push or trigger a GitHub Actions workflow with a controlled failing step.
2. Wait for `github-actions-exporter` to scrape the failed run.
3. Open the DORA dashboard and capture Change Failure Rate.
4. Confirm `HighChangeFailureRate` fires when CFR exceeds the threshold.
5. Capture the Slack firing notification in `#DevOps-Alerts`.
6. Fix the workflow and trigger a successful run.
7. Capture the recovery trend and resolved notification.

Evidence placeholders:

- Screenshot: failed GitHub Actions run
- Screenshot: DORA CFR panel
- Screenshot: Slack firing alert
- Screenshot: successful recovery run

## Scenario 2: Latency Injection

Goal: prove the SLO burn pipeline works from latency degradation to trace correlation.

Steps:

1. Inject latency on the application server using an app-level delay or traffic control.
2. Confirm Blackbox p95 latency increases.
3. Confirm SLO burn rate increases on the SLO dashboard.
4. Wait for `SloLatencyBurnRate`, `SloBurnRateSlow`, or `SloBurnRateFast`.
5. Capture Slack firing notification.
6. Use the Unified Observability dashboard to inspect the same time window.
7. Open Loki logs and click a `traceID` derived field into Tempo.
8. Remove the latency and capture resolved Slack notification.

Evidence placeholders:

- Screenshot: latency injection command
- Screenshot: Blackbox p95 latency
- Screenshot: SLO burn panel
- Screenshot: Slack alert
- Screenshot: Loki log with clickable trace ID
- Screenshot: Tempo trace
- Screenshot: recovery

## Scenario 3: Resource Pressure

Goal: prove warning, critical, and recovery alerts work.

Steps:

1. Generate CPU or memory pressure on the target host.
2. Wait for the warning threshold.
3. Continue pressure until the critical threshold.
4. Capture warning and critical Slack alerts.
5. Stop the pressure process.
6. Capture resolved Slack notification.

Evidence placeholders:

- Screenshot: pressure command
- Screenshot: Node Exporter CPU or memory panel
- Screenshot: warning Slack alert
- Screenshot: critical Slack alert
- Screenshot: resolved Slack alert

## Notes for the final blog

Explain what failed, how quickly detection happened, how long response took, and which automation reduced manual toil.
