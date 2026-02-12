# watchtower

Deploys [Watchtower](https://containrrr.dev/watchtower/) to automatically update running Docker containers.

## Variables

```yaml
watchtower:
  enabled: true
  container_name: watchtower
  config:
    schedule: "0 30 4 * * *"   # Cron schedule (default: daily at 04:30)
  metrics:
    enabled: true              # Expose Prometheus metrics on port 8080
```
