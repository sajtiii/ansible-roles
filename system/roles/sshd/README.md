# sshd

Installs OpenSSH server and deploys a templated `sshd_config`.

Default configuration enables pubkey authentication, permits root login with key only (`prohibit-password`), and allows password authentication for regular users.

## Variables

No configurable variables. Edit `templates/sshd_config.j2` to customize.
