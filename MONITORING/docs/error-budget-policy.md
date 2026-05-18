# Error Budget Policy

## Overview
Error budget = maximum allowed unreliability before breaching SLO.

**Availability SLO:** 99.5% over 30 days
**Error Budget:** 0.5% × 43,200 minutes = **216 minutes (3.6 hours)**

---

## Thresholds and Actions

### 25% Consumed (54 minutes used)
- **Action:** Monitor closely
- **Who decides:** On-call engineer
- **Steps:**
  1. Review recent deployments
  2. Check for error patterns in logs
  3. Increase monitoring frequency

### 50% Consumed (108 minutes used)
- **Action:** Slow down feature work
- **Who decides:** Team lead
- **Steps:**
  1. Notify team lead
  2. Pause non-critical deployments
  3. Prioritise reliability fixes
  4. Add weekly reliability review

### 75% Consumed (162 minutes used)
- **Action:** Stop non-critical deployments
- **Who decides:** Engineering manager
- **Steps:**
  1. Notify manager and stakeholders
  2. Only security and reliability fixes deployed
  3. Full root cause analysis for each incident
  4. Daily reliability standup

### 100% Consumed (216 minutes used)
- **Action:** Feature freeze — reliability sprint
- **Who decides:** VP Engineering
- **Steps:**
  1. Immediate feature freeze
  2. Full reliability sprint — all hands on reliability
  3. Executive notification
  4. Post-incident review required
  5. Consider revising SLO target

---

## SLO Review Cadence

| Frequency | Review Type |
|-----------|-------------|
| Monthly | Error budget consumption review |
| Quarterly | SLO target review — adjust if consistently easy/hard |
| After incidents | Verify SLO correctly captured user impact |
| After major features | Assess if new functionality affects reliability |

---

## How SLO Targets Are Adjusted
1. Collect 90 days of data showing current performance
2. Propose new target with justification
3. Team review and consensus
4. Update `slo-definitions.md` and `slo.yml` alert rules
5. Communicate change to all stakeholders
6. Monitor for 30 days to verify new target is appropriate
