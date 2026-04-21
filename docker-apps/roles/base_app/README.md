# base-app

Base role for Docker Compose applications managed with `docker compose` directly (not systemd).

Compose files are deployed to `/srv/<name>/docker-compose.yml`.

## Variables (passed by calling role)

| Variable | Description |
| --- | --- |
| `name` | Application name, used for directory and compose project |
| `service_name` | Service name for handler notifications |
| `enabled` | `true` to deploy, `false` to stop and optionally remove |
| `cleanup` | When `true` and disabled, also removes the app directory (default: `false`) |

## Usage

Include from another role's tasks:

```yaml
- ansible.builtin.include_role:
    name: base-app
  vars:
    name: myapp
    service_name: myapp
    enabled: true
```

The calling role must provide `templates/docker-compose.yml.j2`.
