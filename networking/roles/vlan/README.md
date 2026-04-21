# vlan

Configures 802.1Q VLAN interfaces as systemd services. Stale interfaces previously managed by this role are automatically stopped, disabled, and removed on each run.

## Variables

```yaml
vlans: {}                                  # Map of VLAN ID to VLAN config (see below)
vlan_state_file: /var/lib/ansible/vlans_state.json  # Path to state tracking file
```

### VLAN object

```yaml
vlans:
  55:                            # VLAN ID (key)
    interface: eno1              # optional, base interface (default: ansible_default_ipv4.interface)
    name: servers                # optional, interface name (default: <base_iface>.<vlan_id>)
    ipv4_cidr: 192.168.55.1/24  # optional, IPv4 address/prefix to assign
    ipv6_cidr: fd00:55::1/64    # optional, IPv6 address/prefix to assign
    dhcp: false                 # optional, use DHCP instead of static IP
    dhcp_default_route: false   # optional, allow DHCP to set the default route
```

## How It Works

Each VLAN is managed as a oneshot systemd service (`vlan-<iface_name>.service`) that creates the VLAN interface on start and removes it on stop. A state file tracks which interfaces were previously managed so stale ones can be cleaned up automatically.
