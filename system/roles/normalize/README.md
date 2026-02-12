# normalize

Sets up base system configuration: hostname, hosts file, MOTD, timezone, swappiness, and essential packages.

## Variables

| Variable | Default | Description |
|---|---|---|
| `hostname` | `inventory_hostname` | System hostname |
| `system.motd` | `""` | Message of the day content |
| `system.timezone` | `UTC` | System timezone |
| `system.swappiness` | `10` | Kernel swappiness value |

## Packages Installed

`sudo`, `curl`, `vim`, `restic`
