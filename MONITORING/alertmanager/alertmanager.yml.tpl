# ============================================================
# alertmanager.yml.tpl
# Configures Alertmanager — the alert routing and notification system.
# Receives firing alerts from Prometheus.
# Groups them, applies routing rules, sends to Slack.
# This is a TEMPLATE file — ${slack_webhook_url} is injected
# by Terraform at apply time. Never hardcode secrets here.
# ============================================================

global:
  # How long to wait before sending a resolved notification
  resolve_timeout: 5m
  # Default Slack webhook — injected by Terraform from tfvars
  slack_api_url: "${SLACK_WEBHOOK_URL}"

# ── Templates ────────────────────────────────────────────────
# Load our custom Slack message templates
templates:
  - '/etc/alertmanager/templates/*.tmpl'

# ── Routing ──────────────────────────────────────────────────
# The route tree decides WHERE each alert goes.
# Every alert starts at the root route and works its way down.
route:
  # Group alerts together if they share these labels
  # Prevents getting 50 separate Slack messages for 50 related alerts
  group_by: ['alertname', 'severity', 'service']

  # Wait this long to collect more alerts before sending the group
  group_wait: 30s

  # After sending a group, wait this long before sending updates
  group_interval: 5m

  # If an alert keeps firing, resend notification after this long
  repeat_interval: 4h

  # Default receiver if no child route matches
  receiver: 'slack-notifications'

  # Child routes — more specific routing rules
  routes:
    # Critical alerts get their own route — sent immediately
    - match:
        severity: critical
      receiver: 'slack-critical'
      group_wait: 10s
      repeat_interval: 1h
      continue: false

    # Warning alerts use default grouping
    - match:
        severity: warning
      receiver: 'slack-notifications'
      repeat_interval: 4h
      continue: false

    # SLO burn rate alerts — always go to critical channel
    - match:
        alertname: SloBurnRateFast
      receiver: 'slack-critical'
      group_wait: 0s
      repeat_interval: 30m
      continue: false

# ── Inhibition Rules ─────────────────────────────────────────
# Suppress certain alerts when other alerts are firing.
# Prevents alert storms — if a host is DOWN, we don't need
# to also receive CPU/memory/latency alerts for that host.
inhibit_rules:
  # If a host is completely down, suppress all other alerts for it
  - source_matchers:
      - alertname = "ServerDown"
    target_matchers:
      - severity =~ "warning|critical"
    # Only inhibit if it's the same instance
    equal: ['instance']

  # If CPU critical fires, suppress CPU warning for same instance
  - source_matchers:
      - alertname = "HighCpuCritical"
    target_matchers:
      - alertname = "HighCpuWarning"
    equal: ['instance']

  # If memory critical fires, suppress memory warning
  - source_matchers:
      - alertname = "HighMemoryCritical"
    target_matchers:
      - alertname = "HighMemoryWarning"
    equal: ['instance']

# ── Receivers ────────────────────────────────────────────────
# Receivers define HOW to send notifications.
# We use our custom template for structured Slack payloads.
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#DevOps-Alerts'
        send_resolved: true
        title: '{{ template "slack.title" . }}'
        text: '{{ template "slack.body" . }}'
        color: '{{ template "slack.color" . }}'
        actions:
          - type: button
            text: 'View Dashboard :grafana:'
            url: '{{ template "slack.dashboard_url" . }}'
          - type: button
            text: 'View Runbook :book:'
            url: '{{ template "slack.runbook_url" . }}'

  - name: 'slack-critical'
    slack_configs:
      - channel: '#DevOps-Alerts'
        send_resolved: true
        title: '{{ template "slack.title" . }}'
        text: '{{ template "slack.body" . }}'
        color: '{{ template "slack.color" . }}'
        actions:
          - type: button
            text: 'View Dashboard :grafana:'
            url: '{{ template "slack.dashboard_url" . }}'
          - type: button
            text: 'View Runbook :book:'
            url: '{{ template "slack.runbook_url" . }}'
