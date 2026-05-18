# The Four Golden Signals — SLI Definitions

The Four Golden Signals are the four most critical metrics for monitoring
any service. Defined by Google's SRE book. Instead of watching 100 metrics,
you focus on these 4 to understand service health instantly.

---

## Signal 1 — LATENCY (How Slow?)

**What it measures:**
How long it takes to serve a request.
We distinguish between successful and error request latency — they tell
different stories. Slow errors often indicate retry storms or cascading failures.

**Successful request latency:**
```promql
histogram_quantile(0.95,
  rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m])
)
```
Recording rule: `golden:latency:p95`

**Error request latency:**
```promql
histogram_quantile(0.95,
  rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m])
) * (1 - probe_success{job="blackbox-http"})
```
Recording rule: `golden:latency:errors_p95`

**SLO target:** 95% of requests complete under 500ms (0.5s)
**Why p95:** Averages hide tail latency. 95th percentile shows what
95% of your users actually experience — the other 5% get worse.
**Alert threshold:** `golden:latency:p95 > 0.5`

---

## Signal 2 — TRAFFIC (How Busy?)

**What it measures:**
How much demand the system is handling — requests per second.
Traffic context is essential: errors during high traffic may be normal.
Errors without traffic increase means something broke.

```promql
rate(probe_success{job="blackbox-http"}[5m])
```
Recording rule: `golden:traffic:probe_rate`

**Current baseline:** ~0.033 req/s (Blackbox probes every 30 seconds)
**Why it matters:** Correlates problems with load.
A spike in errors + spike in traffic = capacity problem.
A spike in errors + flat traffic = software problem.

---

## Signal 3 — ERRORS (How Broken?)

**What it measures:**
The rate of requests that fail. We track three types:

**Explicit errors (HTTP non-2xx responses):**
```promql
(1 - avg(probe_success{job="blackbox-http"})) * 100
```
Recording rule: `golden:errors:percentage`

**Implicit errors (connection refused, timeouts):**
```promql
1 - avg(probe_success{job="blackbox-http"})
```
Recording rule: `golden:errors:rate`

**Policy failures (requests exceeding latency SLO):**
```promql
histogram_quantile(0.95,
  rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m])
) > 0.5
```
Recording rule: `golden:errors:latency_slo_violations`

**SLO target:** Less than 0.5% error rate (99.5% availability)
**Why three types:** Explicit errors are caught by HTTP status codes.
Implicit errors are network-level failures. Policy failures are requests
that technically succeeded but were too slow to be acceptable.

---

## Signal 4 — SATURATION (How Full?)

**What it measures:**
How close the system is to its capacity limits.
Saturation PREDICTS future problems before they impact users.

**CPU saturation:**
```promql
(1 - avg by(instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
)) * 100
```
Recording rule: `golden:saturation:cpu_percent`
Alert threshold: Warning at 80%, Critical at 90%

**Memory saturation:**
```promql
(1 - (
  node_memory_MemAvailable_bytes /
  node_memory_MemTotal_bytes
)) * 100
```
Recording rule: `golden:saturation:memory_percent`
Alert threshold: Warning at 80%, Critical at 90%

**Disk saturation:**
```promql
(1 - (
  node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs"} /
  node_filesystem_size_bytes{fstype!~"tmpfs|fuse.lxcfs"}
)) * 100
```
Recording rule: `golden:saturation:disk_percent`
Alert threshold: Warning at 75%, Critical at 90%

**Why saturation matters:**
At 90% CPU the system starts queuing requests — latency increases.
At 100% CPU requests start timing out — errors increase.
Saturation lets you act BEFORE the user-facing impact begins.

---

## How the Signals Connect
High TRAFFIC
│
└──► Check SATURATION — is the system at capacity?
│
├── YES → Scale up or shed load
└── NO  → Check ERRORS — what is breaking?
│
└──► Check LATENCY — how slow is it?
│
└──► Identify root cause

All four signals together tell the full story.
One signal alone is never enough.
