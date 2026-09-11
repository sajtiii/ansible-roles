# tailscale

Installs Tailscale, joins the node to a tailnet using a pre-auth key, and optionally advertises it as an exit node. Works with the hosted Tailscale control plane or a self-hosted Headscale server.

## Variables

```yaml
# group_vars / host_vars
tailscale:
  install: true                                      # set false to skip package installation
  login_url: "https://controlplane.tailscale.com"    # control server; use your Headscale URL for self-hosted
  auth_key: "{{ vault_tailscale_auth_key }}"         # pre-auth key used for the initial login
  exit_node: false                                   # advertise this node as an exit node
```

## Behaviour

- **Install** — adds the official Tailscale apt repository and keyring, then installs `tailscale`. On openSUSE MicroOS the package is installed via `transactional-update`.
- **Exit node** — when `exit_node: true`, `/etc/sysctl.d/99-tailscale.conf` enables IPv4 and IPv6 forwarding and `sysctl --system` is reloaded. The file is removed when `exit_node` is false.
- **Login** — if the node is not in the `Running` state, or its current control URL differs from `login_url`, the role runs `tailscale up --reset` with the auth key, login server and exit node flag. Switching control servers adds `--force-reauth`. The command is run with `no_log` so the key is not printed.
- **Exit node changes** — on an already logged-in node, a changed `exit_node` value is applied with `tailscale set --advertise-exit-node=...` without re-authenticating.
- If the node is not logged in and `auth_key` is empty, the login step is skipped with a message so the role can still install and start the daemon.

## Notes

- Pre-auth keys are single-use unless created as reusable; after the first successful login the key is no longer needed, but leaving it in vault is harmless.
- Exit nodes must still be approved in the Tailscale admin console (or via `headscale routes enable`) before clients can use them.
- `tailscale up --reset` clears any preferences set manually on the host (e.g. `--accept-routes`, `--ssh`). Manage those elsewhere if you rely on them.

## OS support

- **Debian/Ubuntu** — installs from `pkgs.tailscale.com` via `apt`.
- **openSUSE MicroOS** — installs `tailscale` via `transactional-update`.

Set `tailscale.install: false` to skip installation on other distributions.
