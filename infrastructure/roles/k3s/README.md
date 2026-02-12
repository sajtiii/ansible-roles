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
```

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
