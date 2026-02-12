# autoheal

Deploys [autoheal](https://github.com/willfarrell/docker-autoheal) to automatically restart unhealthy containers.

## Variables

```yaml
autoheal:
  enabled: true              # Enable/disable the service
  container_name: autoheal   # Docker container name
  config:
    interval: 30             # Health check interval in seconds
```
