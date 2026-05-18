# Blameless Post-Incident Review

**Incident Title:** Monitoring Stack Health Check Connectivity Failure
**Date:** May 2026
**Severity:** P2 — Monitoring Degraded
**Duration:** ~4 hours
**Author:** Vivian & Teammate

---

## Incident Summary
After deploying the LGTM observability stack, the health monitoring system
marked all monitored services as unreachable immediately after startup.
Investigation revealed three stacked networking issues that prevented
the monitoring server from reaching the application server.
No user-facing impact occurred — the application itself worked correctly.
Only the monitoring was non-functional.

---

## Timeline

| Time | Event |
|------|-------|
| 14:00 | Monitoring stack deployed via terraform apply |
| 14:05 | All services started, Grafana accessible |
| 14:10 | Blackbox probes showing all targets as DOWN |
| 14:15 | Investigation begins — probe logs show connection timeouts |
| 14:30 | Hypothesis 1: Wrong target IP in prometheus.yml |
| 14:45 | Confirmed: app_server_ip variable pointing to wrong IP |
| 15:00 | Second issue found: Security group blocking port 9100 |
| 15:30 | Third issue found: Node Exporter not running on app server |
| 15:45 | Node Exporter installed and started on app server |
| 16:00 | Security group rules updated to allow monitoring server |
| 16:10 | prometheus.yml updated with correct app server IP |
| 16:15 | All targets showing as UP in Prometheus |
| 18:00 | Monitoring confirmed stable — incident closed |

---

## Root Cause Analysis

Three independent issues stacked on top of each other:

**Cause 1 — Wrong IP in terraform.tfvars**
The `app_server_ip` variable was set to the monitoring server's own IP
instead of the application server's IP. Prometheus was trying to scrape itself.

**Cause 2 — Security group not updated**
The application server's EC2 security group did not allow inbound connections
from the monitoring server on ports 9100 (Node Exporter) and 9115 (Blackbox).
All connections were rejected at the network level.

**Cause 3 — Node Exporter not installed on app server**
Node Exporter was assumed to be running on the application server but had
not been installed. The application server had no metrics endpoint to scrape.

---

## Impact
- Health monitoring non-functional for 4 hours
- All application targets incorrectly showed as DOWN in Grafana
- No user-facing impact — the application ran correctly throughout
- Alertmanager fired false ServerDown alerts during this period

---

## What Went Wrong in Detection
- No automated check verified monitoring connectivity after deployment
- The terraform apply succeeded but monitoring was silently broken
- No smoke test existed to verify "can monitoring server reach app server?"

---

## What Went Well
- The application itself was completely unaffected
- Root causes were identified systematically one by one
- Fixes were straightforward once causes were identified
- The separation of monitoring from application proved the architecture works

---

## Action Items

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Add connectivity smoke test to terraform | Vivian | May 25 | Open |
| Document security group requirements in README | Vivian | May 18 | Done |
| Add Node Exporter installation to app server setup docs | Vivian | May 18 | Done |
| Add alert for "Prometheus has no targets" | Vivian | May 25 | Open |
| Add terraform output showing monitoring → app connectivity status | Vivian | May 25 | Open |

---

## Lessons Learned
1. **Verify connectivity after deployment** — terraform apply success ≠ monitoring working
2. **Document ALL prerequisites** — Node Exporter on app server must be in README
3. **Security groups are part of IaC** — should be managed by Terraform too
4. **Smoke tests are not optional** — add `terraform output` that verifies connectivity
5. **Separation of concerns works** — monitoring server failure did not affect the app
