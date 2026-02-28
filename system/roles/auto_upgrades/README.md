# auto-upgrades

Configures automatic security and package updates via `unattended-upgrades`.

By default, only security updates are applied automatically.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `auto_upgrades.reboot.enabled` | `false` | Automatic reboot when required (even with logged-in users). |
| `auto_upgrades.reboot.time` | `"02:00"` | Time at which the automatic reboot is scheduled. |
| `auto_upgrades.security` | `true` | Security patches from `Debian-Security`. |
| `auto_upgrades.updates` | `false` | Stable point-release updates (`codename-updates`). |
| `auto_upgrades.backports` | `false` | Packages from `codename-backports`. |
| `auto_upgrades.major` | `false` | Full Debian stable repository. |
| `auto_upgrades.packages.exclude` | `[]` | List of package regex patterns to exclude from upgrades. |
| `auto_upgrades.cleanup` | `true` | Remove unused dependencies after upgrades. |
