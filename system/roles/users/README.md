# users

Creates user accounts with passwords, SSH directories, and authorized keys. Also sets the root password.

## Variables

| Variable | Default | Description |
|---|---|---|
| `root_password` | **required** | Hashed root password |
| `users` | `[]` | List of user objects |

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
