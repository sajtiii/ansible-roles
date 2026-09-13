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
  advertise_routes: []                               # subnet routes to advertise, e.g. ["10.0.0.0/24"]
```

## Behaviour

- **Install** — adds the official Tailscale apt repository and keyring, then installs `tailscale`. On openSUSE MicroOS the package is installed via `transactional-update`.
- **IP forwarding** — when `exit_node: true` or `advertise_routes` is non-empty, `/etc/sysctl.d/99-tailscale.conf` enables IPv4 and IPv6 forwarding and `sysctl --system` is reloaded. The file is removed when neither is set.
- **Login** — only runs `tailscale up` when the node is logged out (backend state is not `Running`). An already logged-in node is never re-authenticated by this role. The command is run with `no_log` so the key is not printed.
- **Settings** — once logged in, `exit_node` and `advertise_routes` are each applied via a shared, reusable task (`tasks/_tailscale_set.yml`) that takes just `key` and `value`: it reads the current value with `tailscale get <key>` and only runs `tailscale set --<key>=<value>` when it differs. `tailscale get` is read-only, so it always runs — including in `--check` mode, where a pending difference is reported via `debug` instead of being applied. Adding another `tailscale set`-managed option is one more `include_tasks: _tailscale_set.yml` block.
- If the node is not logged in and `auth_key` is empty, the login step is skipped with a message so the role can still install and start the daemon.

## Notes

- Pre-auth keys are single-use unless created as reusable; after the first successful login the key is no longer needed, but leaving it in vault is harmless.
- Exit nodes must still be approved in the Tailscale admin console (or via `headscale routes enable`) before clients can use them.
- The role only ever calls `tailscale up` once per login; after that, `exit_node` and `advertise_routes` changes are applied with `tailscale set`, which leaves other preferences (e.g. `--accept-routes`, `--ssh`) untouched.
- Changing `login_url` on an already logged-in node is not handled automatically; re-authenticate manually (`tailscale up --login-server=... --force-reauth`) if you migrate control servers.

## OS support

- **Debian/Ubuntu** — installs from `pkgs.tailscale.com` via `apt`.
- **openSUSE MicroOS** — installs `tailscale` via `transactional-update`.

Set `tailscale.install: false` to skip installation on other distributions.
