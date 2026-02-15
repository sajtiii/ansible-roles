# k3s

Installs and configures k3s (lightweight Kubernetes) with support for dedicated server roles.

## Variables

```yaml
k3s:
  role: both               # both, etcd, control-plane, or agent
  cluster_init: false      # Set true for the first server node in a new cluster
  token: ""                # Cluster token
  server: ""               # Server URL (e.g. https://master:6443)
  metrics:
    enabled: true          # Enable metrics-server (both/control-plane only)
  traefik:
    enabled: false         # Enable built-in Traefik (both/control-plane only)
  wireguard:
    enabled: false         # Enable WireGuard-based distributed networking
    node_external_ip: ""   # External IP for this node (auto-detected from inventory)
  ipv6:
    enabled: false         # Enable IPv6 dual-stack networking
    cluster_cidr: "fd00:42::/56,10.42.0.0/16"  # Dual-stack cluster CIDR (IPv6 first)
    service_cidr: "fd00:43::/112,10.43.0.0/16" # Dual-stack service CIDR (IPv6 first)
    node_cidr_mask_size_ipv4: 24  # IPv4 CIDR mask size for node allocation
    node_cidr_mask_size_ipv6: 64  # IPv6 CIDR mask size for node allocation
    masquerade: false      # Enable IPv6 NAT (useful for ULA ranges)
    node_ip: ""            # Explicitly set node IP (auto-detected from inventory)
```

### Inventory Variables

You can define these variables in your inventory to automatically populate node IPs:

```yaml
# Optional: Define IPv6/IPv4 addresses in inventory
ipv6_address: "2001:db8::1"  # Used for node_external_ip and node_ip
ipv4_address: "192.0.2.1"    # Used for node_ip (dual-stack)

# Or rely on ansible_host
ansible_host: 192.0.2.1      # Will be used if ipv4_address not defined
```

**Auto-detection priority:**
1. Explicit `k3s.wireguard.node_external_ip` or `k3s.ipv6.node_ip` (highest priority)
2. Inventory variables: `ipv6_address`, `ipv4_address`
3. Ansible facts: `ansible_default_ipv6.address`, `ansible_default_ipv4.address`

## Roles

| Role | Components | `server` required | `cluster_init` |
|---|---|---|---|
| `both` | etcd + control-plane + worker | Only when joining | First node only |
| `etcd` | etcd only | Only when joining | First node only |
| `control-plane` | apiserver + controller + scheduler | Always | N/A |
| `agent` | kubelet + kube-proxy | Always | N/A |

## Cluster Setup Examples

**Single node:**
```yaml
k3s: { role: both, cluster_init: true }
```

**HA with dedicated roles:**
```yaml
# First etcd node
k3s: { role: etcd, cluster_init: true, token: "secret" }

# Additional etcd nodes
k3s: { role: etcd, server: "https://etcd1:6443", token: "secret" }

# Control-plane nodes
k3s: { role: control-plane, server: "https://etcd1:6443", token: "secret" }

# Worker nodes
k3s: { role: agent, server: "https://cp1:6443", token: "secret" }
```

## WireGuard Networking

Enable WireGuard-based distributed networking for multi-cloud deployments where nodes are spread across different networks:

```yaml
k3s:
  role: both
  cluster_init: true
  wireguard:
    enabled: true
    node_external_ip: "203.0.113.10"  # Public/external IP of this node
```

**Important considerations:**
- Each node requires a unique external IP (usually a public IP)
- On agents, set `K3S_URL` to reference the server's external IP
- Embedded etcd is **not supported** in distributed WireGuard deployments
- If using embedded etcd, all server nodes must be reachable via private IPs

**Example multi-cloud setup:**
```yaml
# Server node (cloud provider A)
k3s:
  role: both
  cluster_init: true
  token: "secret"
  wireguard:
    enabled: true
    node_external_ip: "203.0.113.10"

# Agent node (cloud provider B)
k3s:
  role: agent
  server: "https://203.0.113.10:6443"  # Use external IP
  token: "secret"
  wireguard:
    enabled: true
    node_external_ip: "198.51.100.20"
```

## IPv6 Dual-Stack Networking

Enable IPv6 dual-stack support for cost-effective networking on modern cloud providers:

```yaml
k3s:
  role: both
  cluster_init: true
  ipv6:
    enabled: true
    cluster_cidr: "10.42.0.0/16,fd00:42::/56"
    service_cidr: "10.43.0.0/16,fd00:43::/112"
    node_ip: "2001:db8::1,192.0.2.1"  # IPv6 first (use your actual IPv6)
```

**Important considerations:**
- **IP Ranges**: Use private ranges for cluster/service CIDRs:
  - IPv4: `10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16`
  - IPv6: `fd00::/8` (ULA - Unique Local Addresses) for internal cluster networking
- **CIDR Ordering**: The first IP family in CIDRs must match your node's primary address family:
  - IPv6-primary nodes: Use `fd00:42::/56,10.42.0.0/16` (IPv6 first)
  - IPv4-primary nodes: Use `10.42.0.0/16,fd00:42::/56` (IPv4 first)
  - K3s will auto-detect your primary family from the node's public address
- **Node IPs**: Use your actual node IPs (public or private depending on your setup):
  - Public IPv6 from cloud provider (e.g., `2001:db8::/32` in examples)
  - Or ULA if using private networking only
- When IPv6 is the primary family, explicitly set `node_ip` with IPv6 address first
- If using non-routable IPv6 (ULA range), enable `masquerade: true` for IPv6 NAT to access external services
- If IPv6 default route is set by router advertisement (RA), set sysctl: `net.ipv6.conf.all.accept_ra=2`
- All server nodes must use the same `cluster_cidr` and `service_cidr` values

**Example with IPv6 masquerade for ULA:**
```yaml
k3s:
  ipv6:
    enabled: true
    cluster_cidr: "10.42.0.0/16,fd00:42::/56"
    service_cidr: "10.43.0.0/16,fd00:43::/112"
    masquerade: true  # Enable NAT for ULA range
```

## Combining WireGuard and IPv6

You can enable both WireGuard and IPv6 for distributed dual-stack deployments:

```yaml
k3s:
  role: both
  cluster_init: true
  token: "secret"
  wireguard:
    enabled: true
    node_external_ip: "2001:db8::1"  # Can use IPv6 as external IP
  ipv6:
    enabled: true
    cluster_cidr: "10.42.0.0/16,fd00:42::/56"
    service_cidr: "10.43.0.0/16,fd00:43::/112"
    node_ip: "2001:db8::1,192.0.2.1"
```

### Using Inventory Variables (Recommended)

Instead of hardcoding IPs, define them in your inventory for automatic configuration:

```yaml
# inventory.yml
hosts:
  professor.sajtii.hu:
    ansible_host: 46.225.87.199
    ipv6_address: "2a01:4f8:1c19:770d::1"
    ipv4_address: 46.225.87.199  # Optional, falls back to ansible_host
    k3s:
      role: both
      cluster_init: true
      wireguard:
        enabled: true  # Will use ipv6_address for node_external_ip
      ipv6:
        enabled: true  # Will build node_ip from ipv6_address,ipv4_address
```

The template will automatically:
- Set `node-external-ip` from `ipv6_address` (for WireGuard)
- Build `node-ip` as `ipv6_address,ipv4_address` (for dual-stack)
