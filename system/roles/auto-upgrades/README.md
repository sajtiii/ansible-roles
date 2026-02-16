# auto-upgrades

Configures automatic security and package updates via `unattended-upgrades`.

By default, only security updates are applied automatically.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `auto_upgrades.reboot` | `false` | Automatic reboot at 02:00 when required (even with logged-in users). |
| `auto_upgrades.security` | `true` | Security patches from `Debian-Security`. |
| `auto_upgrades.updates` | `false` | Stable point-release updates (`codename-updates`). |
| `auto_upgrades.backports` | `false` | Packages from `codename-backports`. |
| `auto_upgrades.mayor` | `false` | Full Debian stable repository. |
| `auto_upgrades.packages.blacklist` | `[]` | List of package regex patterns to exclude from upgrades. |
