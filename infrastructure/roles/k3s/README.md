# k3s

Installs and configures k3s (lightweight Kubernetes) as server, agent, or both.

## Variables

```yaml
k3s:
  role: master             # master, agent, or both
  token: ""                # Cluster token (auto-generated on first master if empty)
  server: ""               # Server URL, required for agent (e.g. https://master:6443)
  metrics:
    enabled: true          # Enable metrics-server (server only)
  traefik:
    enabled: false         # Enable built-in Traefik ingress (server only)
```

## Notes

- `master` / `both` install k3s in server mode (systemd service: `k3s`)
- `agent` installs k3s in agent mode (systemd service: `k3s-agent`) and requires `server` and `token`
- Configuration is written to `/etc/rancher/k3s/config.yaml`
