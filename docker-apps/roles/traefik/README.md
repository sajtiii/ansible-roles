# traefik

Deploys Traefik v3 as a reverse proxy with automatic Let's Encrypt certificates via Cloudflare DNS challenge.

## Variables

```yaml
traefik:
  enabled: true
  container_name: traefik
  metrics:
    enabled: true                  # Expose Prometheus metrics
  cert_dumper:
    enabled: false                 # Deploy traefik-certs-dumper sidecar
  config:
    letsencrypt:
      email: admin@example.com     # required, ACME account email
      cloudflare:
        token: "cf-api-token"      # required, Cloudflare DNS API token
```

## Ports

- `80` — HTTP (redirects to HTTPS)
- `443` — HTTPS (TCP + UDP/QUIC)
- `8080` — Traefik dashboard/API (insecure)
- `9200` — Prometheus metrics (only when `metrics.enabled: true` and `monitoring.enabled: true`)

## Notes

- Let's Encrypt certificates are stored in `/srv/traefik/certs/acme.json`
- Prometheus metrics require both `traefik.metrics.enabled` and the `monitoring` role's `monitoring.enabled` to be `true`
