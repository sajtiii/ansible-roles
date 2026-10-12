# normalize

Sets up base system configuration: hostname, hosts file, MOTD, timezone, swappiness, reboot-on-hang (kernel panic sysctls and systemd hardware watchdog; lockup panics on bare metal only), inotify limits, and essential packages.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `hostname` | `inventory_hostname` | System hostname |
| `system.motd` | `""` | Message of the day content |
| `system.timezone` | `UTC` | System timezone |
| `system.swappiness` | `10` | Kernel swappiness value |
| `system.watchdog` | `30s` | systemd `RuntimeWatchdogSec`; `off` disables the hardware watchdog |

## Packages Installed

`sudo`, `curl`, `vim`, `htop`
