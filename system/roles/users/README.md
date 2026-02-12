# users

Creates user accounts with passwords, SSH directories, and authorized keys. Also sets the root password.

Users removed from the list are automatically deleted on the next run.

## Variables

| Variable | Default | Description |
|---|---|---|
| `root_password` | **required** | Hashed root password |
| `users` | `[]` | List of user objects |
| `users_remove_home` | `true` | Remove home directory when deleting a user |

### User object

```yaml
users:
  - name: john              # required
    password: "$6$..."      # required, hashed
    shell: /bin/bash         # optional, default: /bin/bash
    comment: ""              # optional
    groups: [docker, sudo]   # optional, default: []
    home: /home/john         # optional, default: /home/<name>
    authorized_keys:         # optional
      - "ssh-ed25519 ..."
```

## How Cleanup Works

The role tracks managed usernames in `/etc/ansible-managed-users`. On each run, any user present in that file but absent from the current `users` list is removed. Set `users_remove_home: false` to keep home directories on deletion.
