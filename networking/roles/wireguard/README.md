# wireguard

Configures WireGuard interfaces for node interconnect. Supports multiple interfaces, mesh and hub-spoke topologies, automatic IP assignment, and cleanup of stale interfaces.

Requires the `ansible.utils` collection.

## Topologies

- **mesh** — every node peers with every other node
- **hub-spoke** — first node is the hub; spokes only peer with the hub and route all interconnect traffic through it

## IP Assignment

Addresses are assigned automatically from the CIDRs in dict insertion order. Position 1 gets `.1`/`::1`, position 2 gets `.2`/`::2`, etc. The same order determines which node is the hub in hub-spoke topology.

## Variables

```yaml
# group_vars
wireguard:
  interfaces:
    wg-interconnect:
      port: 51820
      ipv4_cidr: "10.10.0.0/24"
      ipv6_cidr: "fd00:10:10::/64"  # set to false to disable IPv6
      topology: mesh                # mesh | hub-spoke
      keepalive: 25                 # optional, default 25
      mtu: 1420                     # optional, default 1420
      preshared_key: ""             # optional, shared fallback across all peers
      nodes:                        # key = inventory_hostname; order = IP order; first = hub
        myhost1:
          private_key: "{{ vault_wg_myhost1_privkey }}"
          public_key: "<pubkey>"
          endpoint: "1.2.3.4"      # optional, defaults to node key (inventory_hostname)
          preshared_key: ""        # optional, overrides interface-level preshared_key
          post_up: []              # optional, list of PostUp commands (wg-quick hook)
          pre_down: []             # optional, list of PreDown commands (wg-quick hook)
        myhost2:
          private_key: "{{ vault_wg_myhost2_privkey }}"
          public_key: "<pubkey>"
        myhost3:
          private_key: "{{ vault_wg_myhost3_privkey }}"
          public_key: "<pubkey>"
```

## Notes

- Each host only configures interfaces where it appears in `nodes`.
- Ansible-managed config files for interfaces no longer in `wireguard.interfaces` are automatically stopped, disabled, and removed.
- `/etc/hosts` is updated with WireGuard IP addresses for all nodes in each interface.
