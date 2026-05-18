# Live Presentation Outline

## 1. Architecture and Data Flow

- Application server remains separate.
- Monitoring server runs systemd-managed LGTM services.
- Prometheus scrapes metrics and evaluates rules.
- OpenTelemetry Collector receives app traces/logs and forwards them to Tempo/Loki.
- Grafana reads Prometheus, Loki, and Tempo.
- Alertmanager sends structured Slack alerts.

## 2. Four Golden Signals

- Latency: p50, p95, p99 Blackbox response time.
- Traffic: synthetic request rate from Blackbox probes.
- Errors: failed probe ratio and latency policy failures.
- Saturation: CPU, memory, disk, and network utilization.

## 3. SLI to SLO to Error Budget to Alert

- Availability SLO: 99.5% over 30 days.
- Error budget: 216 minutes per 30 days.
- Fast burn: 14.4x.
- Slow burn: 5x.
- Error budget policy defines when delivery slows or freezes.

## 4. DORA Metrics

- Deployment Frequency from successful GitHub Actions runs.
- Lead Time from workflow duration histogram.
- Change Failure Rate from failed workflow conclusions.
- MTTR from Alertmanager active alert duration.
- Dashboard shows DORA benchmark classification.

## 5. Dashboards

- DORA Metrics.
- SLO and Error Budget.
- Node Exporter.
- Blackbox Exporter.
- Unified Observability with metric-to-log-to-trace drill-down.

## 6. Alerting and Slack

- Prometheus rule files are version controlled.
- Alertmanager groups by service and severity.
- Inhibition suppresses noisy resource alerts when server is unreachable.
- Slack payload includes status, severity, host, value, dashboard, and runbook.

## 7. Game Day

- Deployment failure.
- Latency injection.
- Resource pressure.
- Show screenshots for trigger, degradation, alert, trace, and recovery.

## 8. Incident Management

- Read one runbook.
- Walk through the blameless PIR.
- Explain action items, owners, and due dates.
