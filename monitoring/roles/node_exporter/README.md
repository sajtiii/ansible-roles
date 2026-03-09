# node-exporter

Installs Prometheus node_exporter as a systemd service with systemd collector enabled.

## Variables

```yaml
node_exporter:
  version: 1.10.2         # node_exporter release version
  host: 0.0.0.0           # Listen address
  port: 9100              # Listen port
```

## Notes

- Runs as a dedicated `node_exporter` user/group
- Binary installed to `/opt/node_exporter/`
- Config at `/etc/node_exporter/config.yaml`
