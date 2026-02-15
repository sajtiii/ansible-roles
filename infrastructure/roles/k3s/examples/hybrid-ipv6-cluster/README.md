# Hybrid IPv6 k3s Cluster on Hetzner

This example demonstrates how to set up a hybrid k3s cluster where:
- **Nodes communicate via IPv6** using WireGuard native backend
- **Control plane is accessible via IPv4**
- **Pods and services use dual-stack** (IPv6 internally, IPv4 externally)
- **2 IPv6-only nodes** for internal workloads
- **2 Dual-stack nodes** serve as IPv4 entrypoints for external access

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    k3s Cluster                               │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────┐│
│  │  Server 1   │  │  Server 2   │  │   Agent 1   │  │ Ag2││
│  │ (Dual-IPv)  │  │ (IPv6-only) │  │ (Dual-IPv)  │  │(v6)││
│  │ 203.0.113.1 │  │             │  │ 203.0.113.2 │  │    ││
│  │ 2a01::1     │  │ 2a01::2     │  │ 2a01::3     │  │2a01││
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─┬──┘│
│         │                │                │            │   │
│         └────────────────┴────────────────┴────────────┘   │
│              WireGuard IPv6 Mesh Network                    │
│              (fd00:42::/56 pods, fd00:43::/112 services)   │
└─────────────────────────────────────────────────────────────┘
         ▲                                       ▲
         │ IPv4 Control Plane                   │ IPv4 Traffic
         │ (API: 6443)                          │ (HTTP/HTTPS)
         │                                       │
    Internet (IPv4)                         Internet (IPv4)
```

## Prerequisites

1. **Hetzner Cloud Servers** with:
   - 2 servers with both IPv4 and IPv6
   - 2 servers with IPv6 only
   - All servers in the same network/datacenter for best WireGuard performance

2. **Ansible** installed on your control machine

3. **SSH access** to all servers (via IPv4 or IPv6)

## Configuration

### Step 1: Update Inventory

Edit `inventory.yml` and update:

1. **Server hostnames and IPs**:
   ```yaml
   server1.example.com:
     ansible_host: 203.0.113.1  # Your actual IPv4
     ipv4_address: 203.0.113.1
     ipv6_address: "2a01:4f8:1234:5678::1"  # Your actual IPv6
   ```

2. **Cluster token**:
   ```bash
   # Generate a secure token
   openssl rand -base64 32
   ```

   Update in inventory:
   ```yaml
   k3s:
     token: "YOUR_GENERATED_TOKEN"
   ```

3. **Server URL**:
   Update with the IPv4 address of your first server:
   ```yaml
   k3s:
     server: "https://YOUR_FIRST_SERVER_IPV4:6443"
   ```

4. **API Server Advertise Address**:
   ```yaml
   k3s:
     api_server:
       advertise_address: "YOUR_FIRST_SERVER_IPV4"
   ```

### Step 2: Run Playbook

```bash
# Deploy the cluster
ansible-playbook -i inventory.yml playbook.yml
```

Example playbook (`playbook.yml`):
```yaml
---
- name: Deploy k3s hybrid IPv6 cluster
  hosts: k3s_cluster
  become: true
  roles:
    - k3s
```

### Step 3: Verify Cluster

```bash
# SSH to the first server
ssh root@203.0.113.1

# Check cluster status
kubectl get nodes -o wide

# Should show nodes with both IPv4 and IPv6 addresses
# IPv6-only nodes will show only IPv6
# Dual-stack nodes will show IPv6 (primary) and IPv4
```

Example output:
```
NAME                 STATUS   ROLES                  AGE   VERSION   INTERNAL-IP                           EXTERNAL-IP
server1.example.com  Ready    control-plane,master   5m    v1.28.5   2a01:4f8:1234:5678::1,203.0.113.1    203.0.113.1,2a01:4f8:1234:5678::1
server2.example.com  Ready    control-plane,master   4m    v1.28.5   2a01:4f8:1234:5679::1                <none>
agent1.example.com   Ready    <none>                 3m    v1.28.5   2a01:4f8:1234:5680::1,203.0.113.2    203.0.113.2,2a01:4f8:1234:5680::1
agent2.example.com   Ready    <none>                 3m    v1.28.5   2a01:4f8:1234:5681::1                <none>
```

### Step 4: Verify WireGuard

```bash
# Check WireGuard is active
kubectl get nodes -o yaml | grep -A 5 annotations

# Check flannel
kubectl get pods -n kube-flannel -o wide

# Verify IPv6 connectivity between nodes
kubectl run test-pod --image=busybox --command -- sleep 3600
kubectl exec test-pod -- ping6 -c 3 2a01:4f8:1234:5679::1
```

## How It Works

### Node Communication

1. **WireGuard Native Backend**: k3s uses `flannel-backend: wireguard-native` which automatically creates encrypted WireGuard tunnels between all nodes over IPv6.

2. **Node IP Priority**:
   - `node-ip: ipv6,ipv4` - IPv6 is listed first, so nodes prefer IPv6 for internal cluster communication
   - WireGuard encrypts all pod-to-pod traffic across nodes

3. **External IP**:
   - `node-external-ip: ipv4,ipv6` - IPv4 is listed first for external access
   - Only dual-stack nodes have this configured

### Pod Networking

1. **Dual-stack CIDRs**:
   - Pods get both IPv4 (`10.42.0.0/16`) and IPv6 (`fd00:42::/56`) addresses
   - Services get both IPv4 (`10.43.0.0/16`) and IPv6 (`fd00:43::/112`) addresses

2. **Traffic Flow**:
   - Pod-to-pod within same node: Direct IPv6
   - Pod-to-pod across nodes: IPv6 over WireGuard tunnel
   - External to pod: IPv4 → Dual-stack node → IPv6 pod

### Control Plane Access

- API server binds to `0.0.0.0` (IPv4) on port 6443
- Advertises IPv4 address for cluster joining
- All nodes (even IPv6-only) can reach control plane via WireGuard

## External Access Patterns

### Pattern 1: External Traefik (Recommended)

Deploy Traefik separately on dual-stack nodes:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik
spec:
  type: LoadBalancer
  ipFamilyPolicy: PreferDualStack
  ipFamilies: [IPv4, IPv6]
  ports:
    - name: web
      port: 80
      targetPort: 8080
    - name: websecure
      port: 443
      targetPort: 8443
  selector:
    app: traefik
```

### Pattern 2: NodePort on Dual-stack Nodes

Configure NodePort services to use dual-stack nodes as entrypoints:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort
  ipFamilyPolicy: PreferDualStack
  ipFamilies: [IPv4, IPv6]
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080
  selector:
    app: my-app
```

Access via: `http://203.0.113.1:30080` or `http://203.0.113.2:30080`

### Pattern 3: HostNetwork Pods

Run ingress controllers with `hostNetwork: true` on dual-stack nodes:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: my-ingress
spec:
  selector:
    matchLabels:
      app: my-ingress
  template:
    spec:
      hostNetwork: true
      nodeSelector:
        node.kubernetes.io/external-ip: "true"  # Select dual-stack nodes
      containers:
        - name: ingress
          image: traefik:latest
          ports:
            - containerPort: 80
              hostPort: 80
            - containerPort: 443
              hostPort: 443
```

## Troubleshooting

### Nodes Can't Join Cluster

1. Check IPv4 connectivity to control plane:
   ```bash
   curl -k https://203.0.113.1:6443
   ```

2. Verify token is correct:
   ```bash
   cat /etc/rancher/k3s/config.yaml | grep token
   ```

### WireGuard Not Working

1. Check WireGuard module is loaded:
   ```bash
   lsmod | grep wireguard
   modprobe wireguard
   ```

2. Check flannel logs:
   ```bash
   kubectl logs -n kube-system -l app=flannel
   ```

### IPv6 Connectivity Issues

1. Verify IPv6 is enabled:
   ```bash
   sysctl net.ipv6.conf.all.disable_ipv6
   # Should be 0
   ```

2. Check IPv6 routing:
   ```bash
   ip -6 route
   ```

3. Test IPv6 between nodes:
   ```bash
   ping6 -c 3 2a01:4f8:1234:5679::1
   ```

### Pods Can't Reach Each Other

1. Check pod IPs:
   ```bash
   kubectl get pods -o wide --all-namespaces
   ```

2. Verify CNI is running:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=flannel
   ```

3. Check WireGuard interfaces:
   ```bash
   ip link show | grep flannel
   wg show
   ```

## Advanced Configuration

### Custom CIDR Ranges

To use different IP ranges:

```yaml
k3s:
  ipv6:
    cluster_cidr: "10.42.0.0/16,fd12:3456::/56"  # Custom IPv6 prefix
    service_cidr: "10.43.0.0/16,fd12:3456:1::/112"
```

### Node Affinity for External Access

Label dual-stack nodes for scheduling ingress workloads:

```bash
kubectl label node server1.example.com node.kubernetes.io/external-ipv4=true
kubectl label node agent1.example.com node.kubernetes.io/external-ipv4=true
```

Use in pod specs:
```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node.kubernetes.io/external-ipv4
              operator: Exists
```

## Security Considerations

1. **WireGuard Encryption**: All inter-node traffic is encrypted by WireGuard
2. **API Server**: Only exposed on IPv4, protected by TLS and token auth
3. **Firewall Rules**: Consider restricting:
   - Port 6443/tcp to trusted IPs only (control plane access)
   - Port 80/443 to internet (web traffic)
   - All other ports should be firewalled

Example UFW rules:
```bash
# Allow SSH
ufw allow 22/tcp

# Allow k3s API server (control plane)
ufw allow 6443/tcp

# Allow HTTP/HTTPS (on dual-stack nodes only)
ufw allow 80/tcp
ufw allow 443/tcp

# Allow WireGuard (k3s manages this internally)
# Flannel WireGuard uses dynamic ports

# Enable firewall
ufw enable
```

## Cost Optimization

- **IPv6-only servers** are typically cheaper on Hetzner (~20-30% cost reduction)
- Use IPv6-only nodes for:
  - Database pods
  - Background workers
  - Internal services
- Use dual-stack nodes for:
  - Ingress controllers
  - Load balancers
  - Services requiring external IPv4 access

## References

- [k3s Networking](https://docs.k3s.io/networking)
- [k3s IPv6](https://docs.k3s.io/installation/network-options#dual-stack-ipv4--ipv6-networking)
- [Flannel WireGuard Backend](https://github.com/flannel-io/flannel/blob/master/Documentation/backends.md#wireguard)
- [Kubernetes Dual-stack](https://kubernetes.io/docs/concepts/services-networking/dual-stack/)
