# gitops

Sets up GitOps automation: clones repositories and runs Ansible playbooks on a schedule via cron.

## Variables

```yaml
gitops:
  repositories:                      # required, list of repo objects
    - url: git@github.com:user/repo  # required, git clone URL
      destination: /opt/gitops/myrepo # required, local checkout path
      version: main                  # optional, default: main
      path: /                        # optional, default: /
```

## Notes

- Installs `cron`, `git`, and `ansible` as prerequisites
- Runs `gitops.sh` every 5 minutes via cron
- Logs to `/var/log/gitops.log` with weekly rotation
