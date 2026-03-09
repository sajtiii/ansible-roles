# monitoring

Deploys a Prometheus instance for local metric federation, scraping node-exporter, cAdvisor, Docker daemon metrics, and container-level metrics via Docker service discovery.

## Variables

```yaml
monitoring:
  enabled: true
  container_name: prometheus-federator
  config:
    port: 9090                 # Prometheus listen port
    retention:
      time: "14d"              # Data retention period
```

## Scraped Targets

- Prometheus self
- node-exporter (host)
- cAdvisor (host)
- Docker daemon metrics (host)
- Docker containers with `prometheus.io/scrape=true` label
