# sshd

Installs OpenSSH server and deploys a hardened `sshd_config`.

By default: pubkey-only authentication, root login disabled, all forwarding disabled, verbose logging.

## Variables

```yaml
sshd:
  port: 22                   # SSH listen port
  permit_root_login: false   # Allow root login (pubkey only when true)
  password_auth: false        # Allow password authentication
  max_auth_tries: 3          # Max authentication attempts per connection
  max_sessions: 3            # Max open sessions per connection
  x11_forwarding: false      # Allow X11 forwarding
  agent_forwarding: false    # Allow SSH agent forwarding
  tcp_forwarding: false      # Allow TCP forwarding
```

## Security Defaults

- `LoginGraceTime 30` — 30s to authenticate before disconnect
- `MaxStartups 3:50:10` — rate-limit unauthenticated connections
- `LogLevel VERBOSE` — detailed logging for audit
- `TCPKeepAlive no` + `ClientAliveInterval 300` — detect dead sessions server-side
- `PermitTunnel no`, `PermitUserEnvironment no`, `HostbasedAuthentication no`
- Kerberos and GSSAPI disabled
