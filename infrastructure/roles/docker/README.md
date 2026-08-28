# docker

Installs Docker CE with compose plugin, configures the daemon, and sets up a systemd template service for docker-compose projects.

## Variables

```yaml
docker:
  metrics:
    enabled: true          # Expose Docker daemon metrics
    host: 0.0.0.0          # Metrics listen address
    port: 9323             # Metrics listen port
```

## Extras

- `dx` command — shortcut for `docker exec -it`
- `docker-compose@.service` — systemd template for compose projects in `/etc/docker-compose/`
