# base-service

Base role for Docker Compose applications managed as systemd services via `docker-compose@.service`.

Compose files are deployed to `/etc/docker-compose/<name>-compose.yml`.

## Variables (passed by calling role)

| Variable | Description |
|---|---|
| `name` | Service name, used for compose file and systemd unit |
| `container_name` | Container name for cleanup on disable |
| `enabled` | `true` to deploy and enable, `false` to stop and remove |

## Usage

Include from another role's tasks:

```yaml
- ansible.builtin.include_role:
    name: base-service
  vars:
    name: myservice
    enabled: true
```

The calling role must provide `templates/docker-compose.yml.j2`.
