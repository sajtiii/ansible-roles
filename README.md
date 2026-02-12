# Ansible Playbook

Ansible Galaxy collections for provisioning and managing Debian-based infrastructure.

## Collections

| Collection | Description |
|---|---|
| `sajtii.system` | Base system setup: hostname, users, NTP, SSH, firewall, upgrades |
| `sajtii.infrastructure` | Docker, Caddy, and k3s installation |
| `sajtii.monitoring` | Prometheus node-exporter and cAdvisor |
| `sajtii.ops` | Backup (restic) and GitOps automation |
| `sajtii.docker_apps` | Docker Compose applications: Traefik, Watchtower, monitoring stack |
| `sajtii.drivers` | Hardware drivers (Google Coral Edge TPU) |

## Usage

```bash
# Ping hosts
./run.sh ping <tenant>

# Run playbook
./run.sh run <tenant>
```

Tenants correspond to inventory files (`inventory-<tenant>.yml`).
