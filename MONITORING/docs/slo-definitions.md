# SLO Definitions and Error Budgets

## Availability SLO

Target: 99.5% of HTTP probes return success over a rolling 30-day window.

SLI:

```promql
avg_over_time(probe_success{job="blackbox-http"}[30d]) * 100
```

Reasoning:

- 100% is not realistic for a student platform with deployments and maintenance.
- 99.5% gives 216 minutes of monthly error budget.
- The target is strict enough to detect real user impact without making every small transient event a page.

Error budget:

```text
(1 - 0.995) * 30 days = 216 minutes
```

## Latency SLO

Target: p95 request latency below 500ms.

SLI:

```promql
histogram_quantile(0.95, rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m])) < 0.5
```

Reasoning:

- 500ms is noticeable but still practical for the app and monitoring environment.
- p95 catches tail latency without overreacting to rare outliers.

Error budget:

```text
5% of requests may exceed 500ms.
```

## Error Rate SLO

Target: 99% of probes succeed.

SLI:

```promql
avg_over_time(probe_success{job="blackbox-http"}[30d]) * 100 > 99
```

Reasoning:

- This separates normal transient failures from sustained incidents.
- It supports burn-rate alerting before users experience a long outage.

Error budget:

```text
1% of probes may fail.
```

## Retention

| Component | Retention | Configuration |
| --- | --- | --- |
| Prometheus | 30 days | `systemd/prometheus.service` |
| Loki | 744 hours | `loki/loki-config.yml` |
| Tempo | 720 hours | `tempo/tempo-config.yml` |
