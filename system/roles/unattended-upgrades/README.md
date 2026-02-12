# unattended-upgrades

Configures automatic security and package updates via `unattended-upgrades`.

## Variables

No configurable variables. Edit templates in `templates/` to customize apt configuration:

- `20auto-upgrades.j2` — Update and upgrade intervals
- `50unattended-upgrades.j2` — Package origins and behavior
