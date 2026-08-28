# gitops

Sets up GitOps automation: clones repositories and runs update scripts on a schedule via cron.

## Variables

```yaml
gitops:
  dependencies:
    install: true           # install packages listed below
    packages:               # default list
      - cron
      - git
      - gettext-base
      - coreutils
      - jq
    exclude: []             # packages to remove from the install list
  bws:
    version: "2.0.0"
    download_url: "https://github.com/bitwarden/sdk-sm/releases/download/bws-v2.0.0/bws-x86_64-unknown-linux-gnu-2.0.0.zip"
    server_url: ""          # optional custom BWS server URL
  cron:
    install: true
  logging:
    discord:
      webhook_url: ""       # optional, posts failure embeds to Discord

  repositories:             # required
    - url: git@github.com:user/repo   # required
      destination: /opt/gitops/myrepo # required, also used as the working directory
      version: main                   # optional, default: main
      path: /                         # optional, subdirectory passed to update.sh
      key: my-repo                    # optional, derived from destination if omitted
      schedule: "*/5 * * * *"         # optional, default: every 5 minutes
      envs: []                        # optional, see Environment sources below
```

## Environment sources

Each entry under `envs` has a `type` field. Sources are combined in order.

```yaml
envs:
  - type: static
    env:
      MY_VAR: "value"

  - type: file
    path: /etc/myapp/secrets.env   # sourced on the remote host

  - type: bitwarden-project
    project_id: "<uuid>"
    access_token: "{{ vault_bws_token }}"

  - type: bitwarden-entry
    entry_id: "<uuid>"             # exports the secret as KEY=value
    access_token: "{{ vault_bws_token }}"

  - type: bitwarden-multientry
    entry_id: "<uuid>"             # secret value is a multi-line KEY=value block
    access_token: "{{ vault_bws_token }}"
```

When any Bitwarden source is present the `bws` binary is downloaded locally and copied to `<destination>/bin/bws`.

## Notes

- Each repository gets its own `gitops.sh` copied to `<destination>/gitops.sh`.
- `envs.sh` is generated at `<destination>/envs.sh` and sourced before running `update.sh`.
- The script re-runs when git changes **or** when environment variables change (hash comparison).
- `gitops.conf` (containing `DISCORD_WEBHOOK_URL`) is written at `<destination>/gitops.conf` when a webhook URL is set.
- Cron job files live at `/etc/cron.d/gitops_<key>`; stale entries for removed repositories are cleaned up automatically.
- Logs to `/var/log/gitops.log` with weekly rotation.
