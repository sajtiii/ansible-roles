# docker

Installs Docker CE with compose plugin, configures the daemon, and sets up a systemd template service for docker-compose projects.

## Variables

```yaml
docker:
  metrics:
    enabled: true          # Expose Docker daemon metrics
    host: 0.0.0.0          # Metrics listen address
    port: 9323             # Metrics listen port
  autoheal:
    enabled: true          # Install the autoheal cron job
    schedule: "*/2 * * * *" # Cron schedule
    include_exited: true   # Also start exited containers (restart policy other than "no")
```

## Extras

- `dx` command — shortcut for `docker exec -it`
- `docker-autoheal` — cron job that restarts unhealthy containers and starts exited ones; logs to syslog under the `docker-autoheal` tag
- `docker-compose@.service` — systemd template for compose projects in `/etc/docker-compose/`
