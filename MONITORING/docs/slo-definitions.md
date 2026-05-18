# SLO Definitions & Error Budgets

## What is an SLO?
A Service Level Objective (SLO) is a target for how reliable a service should be.
It is measured by a Service Level Indicator (SLI) — a specific metric.

---

## SLO 1 — Availability

**SLO Target:** 99.5% of HTTP probes return 2xx over a rolling 30-day window

**SLI PromQL:**
avg_over_time(probe_success{job="blackbox-http"}[30d]) * 100

**Reasoning:**
- 100% is impossible — maintenance windows, deployments, failures happen
- 99% = 7.2 hours downtime/month — too much for a platform
- 99.5% = 3.6 hours downtime/month — appropriate for internal platform
- 99.9% = 43 minutes — too strict for current team size

**Error Budget:**
- Budget = 1 - 0.995 = 0.005 = 0.5%
- 0.5% of 30 days = 0.5% × 43,200 minutes = 216 minutes = 3.6 hours

---

## SLO 2 — Latency

**SLO Target:** 95% of requests complete under 500ms

**SLI PromQL:**
histogram_quantile(0.95,
rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m])
) < 0.5

**Reasoning:**
- 500ms is the threshold where users notice slowness
- 95th percentile captures most users without being too strict
- 99th percentile would require over-engineering for edge cases

**Error Budget:**
- 5% of requests can exceed 500ms
- Over 1 million requests, 50,000 can be slow

---

## SLO 3 — Error Rate

**SLO Target:** 99% of requests succeed (non-5xx)

**SLI PromQL:**
avg_over_time(probe_success{job="blackbox-http"}[30d]) * 100 > 99

**Reasoning:**
- 1% error rate acceptable for internal development platform
- Production user-facing services target 99.9%
- Allows for transient errors without paging

**Error Budget:**
- 1% of requests can fail
- Over 1 million requests, 10,000 can error

---

## Data Retention Periods

| Component | Retention | Reason |
|-----------|-----------|--------|
| Prometheus | 30 days | Matches SLO measurement window |
| Loki | 31 days (744h) | Slightly longer than Prometheus for correlation |
| Tempo | 30 days (720h) | Matches Prometheus for trace correlation |
