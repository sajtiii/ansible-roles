# wireguard

Configures WireGuard interfaces for node interconnect. Supports mesh and hub-spoke topologies with automatic IP assignment.

Requires the `ansible.utils` collection.

## Topologies

- **mesh** — every node peers with every other node
- **hub-spoke** — first node is the hub; spokes only peer with the hub and route all interconnect traffic through it

## IP Assignment

Addresses are assigned automatically from the CIDRs in dict insertion order. Position 1 gets `.1`/`::1`, position 2 gets `.2`/`::2`, etc.

## Variables

```yaml
# group_vars
wireguard:
  interface: wg-interconnect
  port: 51899
  ipv4_cidr: "10.10.0.0/16"
  ipv6_cidr: "fd00:10:10::/64"
  topology: mesh              # mesh | hub-spoke
  keepalive: 25
  preshared_key: "{{ vault_wireguard_psk }}"

  nodes:                      # key = ansible_host; order = IP order; first = hub
    10.0.0.1:
      public_key: "<pubkey>"
    10.0.0.2:
      public_key: "<pubkey>"
    10.0.0.3:
      public_key: "<pubkey>"
```

```yaml
# host_vars/<hostname>.yml
wireguard_private_key: "{{ vault_wireguard_private_key }}"
```
