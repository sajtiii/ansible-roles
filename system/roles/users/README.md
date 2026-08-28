# users

Creates user accounts with passwords, SSH directories, and authorized keys. Also sets the root password.

Users removed from the list are automatically deleted on the next run.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `root_password` | **required** | Hashed root password |
| `users` | `[]` | List of user objects |
| `users_remove_home` | `true` | Remove home directory when deleting a user |

### User object

```yaml
users:
  - username: john          # required
    password: "$6$..."      # required, hashed
    name: "John Doe"        # optional, GECOS/comment field
    shell: /bin/bash        # optional, default: /bin/bash
    groups: [docker, sudo]  # optional, default: []
    home: /home/john        # optional, default: /home/<username>
    authorized_keys:        # optional
      - "ssh-ed25519 ..."
```

## How Cleanup Works

The role tracks managed usernames in `/etc/ansible-managed-users`. On each run, any username present in that file but absent from the current `users` list is removed. Set `users_remove_home: false` to keep home directories on deletion.
