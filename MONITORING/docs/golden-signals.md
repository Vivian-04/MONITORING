# Four Golden Signals - SLI Definitions

These SLIs define what reliability means for the monitored application.

## Latency

Latency measures how long requests take. Successful and failed requests are considered separately because slow failures often indicate timeout or retry behavior.

Successful request p95:

```promql
histogram_quantile(0.95, rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m]))
```

Error request p95:

```promql
histogram_quantile(0.95, rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m]))
  * (1 - probe_success{job="blackbox-http"})
```

SLO target: p95 under 500ms.

## Traffic

Traffic measures synthetic demand handled by the service.

```promql
count(probe_success{job="blackbox-http"}) / 15
```

The denominator matches the 15-second scrape interval.

## Errors

Errors measure failed probes and policy failures.

Failed probe ratio:

```promql
1 - avg(probe_success{job="blackbox-http"})
```

Failed probe percentage:

```promql
(1 - avg(probe_success{job="blackbox-http"})) * 100
```

Latency policy failure:

```promql
histogram_quantile(0.95, rate(probe_duration_seconds_bucket{job="blackbox-http"}[5m])) > 0.5
```

SLO target: at least 99.5% successful probes over 30 days.

## Saturation

Saturation measures how full the system is.

CPU:

```promql
(1 - avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100
```

Memory:

```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

Disk:

```promql
(1 - (
  node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs"} /
  node_filesystem_size_bytes{fstype!~"tmpfs|fuse.lxcfs"}
)) * 100
```

Network:

```promql
rate(node_network_receive_bytes_total{device!~"lo|docker.*|veth.*"}[5m])
rate(node_network_transmit_bytes_total{device!~"lo|docker.*|veth.*"}[5m])
```

Warning thresholds: CPU 80%, memory 80%, disk 75%.
Critical thresholds: CPU 90%, memory 90%, disk 90%.
