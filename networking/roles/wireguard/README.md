# wireguard

Configures WireGuard interfaces for node interconnect. Supports multiple interfaces, mesh and hub-spoke topologies, flexible IP assignment, and cleanup of stale interfaces.

Requires the `ansible.utils` collection.

## Topologies

- **mesh** — every node peers with every other node
- **hub-spoke** — first node is the hub; spokes only peer with the hub and route all interconnect traffic through it

## IP Assignment

IPs can be assigned three ways, evaluated in order per node:

1. **Explicit** — set `ipv4` on the node entry.
2. **Pool** — set `ipv4.auto_assign` on the interface; nodes without an explicit IP draw sequentially from the pool.
3. **Subnet offset** (default fallback) — node's position in dict insertion order maps to `.1`, `.2`, etc.

IPv6 is derived automatically from the last octet of the IPv4 address (decimal digits treated as hex, e.g. `.52` → `::52`).

## Variables

```yaml
# group_vars
wireguard:
  install: true             # set false to skip package installation
  interfaces:
    wg-interconnect:
      port: 51820
      ipv4:
        cidr: "10.10.0.0/24"
        auto_assign:              # optional
          enabled: true
          pool_start: "10.10.0.200"
          pool_end: "10.10.0.254"
      ipv6:                       # optional; omit to disable IPv6
        cidr: "fd00:10:10::/64"
      topology: mesh              # mesh | hub-spoke
      keepalive: 25               # optional, default 25
      mtu: 1420                   # optional, default 1420
      preshared_key: ""           # optional, shared fallback across all peers
      nodes:                      # key = inventory_hostname; first entry = hub in hub-spoke
        myhost1:
          private_key: "{{ vault_wg_myhost1_privkey }}"
          public_key: "<pubkey>"
          ipv4: "10.10.0.10"      # optional, explicit IP
          endpoint: "1.2.3.4"    # optional, defaults to inventory_hostname
          preshared_key: ""      # optional, overrides interface-level preshared_key
          additional_hosts: []   # extra hostname aliases in /etc/wireguard/hosts (same WireGuard IP)
          post_up: []            # optional, list of PostUp commands (wg-quick hook)
          pre_down: []           # optional, list of PreDown commands (wg-quick hook)
        myhost2:
          private_key: "{{ vault_wg_myhost2_privkey }}"
          public_key: "<pubkey>"
        myhost3:
          private_key: "{{ vault_wg_myhost3_privkey }}"
          public_key: "<pubkey>"
```

## OS support

- **Debian/Ubuntu** — installs `wireguard` via `apt`.
- **openSUSE MicroOS** — installs `wireguard-tools` via `transactional-update`.

Set `wireguard.install: false` to skip installation on other distributions.

## Notes

- Each host only configures interfaces where it appears in `nodes`.
- Ansible-managed config files for interfaces no longer in `wireguard.interfaces` are automatically stopped, disabled, and removed.
- `/etc/wireguard/hosts/<interface>` is written on the hub node (hub-spoke) or the first node (mesh) with WireGuard IP addresses and any `additional_hosts` aliases for all nodes in that interface. It is intended for use as a `hostsdir` source by a DNS server such as dnsmasq.
