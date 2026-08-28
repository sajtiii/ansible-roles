# backup

Configures automated Restic backups over SFTP with cron scheduling.

## Variables

```yaml
backup:
  encryption_key: "secret"           # required, Restic repository encryption key
  folders:                           # required, list of paths to back up
    - /srv
    - /etc
  repository:
    base_path: /backups              # required, base path on remote
    sftp:                            # SFTP transport config
      hostname: backup.example.com   # required
      port: 22                       # optional, default: 22
      user: backup                   # required
      private_key: |                 # required, SSH private key
        -----BEGIN OPENSSH PRIVATE KEY-----
        ...
```

## Notes

- Backups run daily at 03:00 via cron
- Encryption key stored at `/etc/restic/encryption_key`
- SSH key stored at `/etc/restic/id_rsa`
