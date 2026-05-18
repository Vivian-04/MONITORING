global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    environment: production
    team: devops

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

rule_files:
  - "/etc/prometheus/rules/*.yml"

scrape_configs:

  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter"
    scrape_interval: 15s
    static_configs:
      - targets: ["localhost:9100"]
        labels:
          instance: "localhost"
          service: "infrastructure"

  - job_name: "blackbox-http"
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://${APP_HOST}:8080/
          - http://${APP_HOST}:8080/healthz
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115

  - job_name: "github-actions"
    metrics_path: /metrics
    static_configs:
      - targets: ["localhost:9117"]
        labels:
          service: cicd
          instance: github-actions

  - job_name: "blackbox-ssl"
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://${APP_HOST}/
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115

  - job_name: "alertmanager"
    static_configs:
      - targets: ["localhost:9093"]

  - job_name: "grafana"
    static_configs:
      - targets: ["localhost:3000"]

  - job_name: "loki"
    static_configs:
      - targets: ["localhost:3100"]
