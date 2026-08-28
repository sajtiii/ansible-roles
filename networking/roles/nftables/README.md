# nftables

Disables other firewalls (firewalld, ufw) and sets up nftables with netfilter-persistent.

## Variables

```yaml
nftables:
  ipv4:
    allowed_ports:
      - port: 22                    # required
        protocol: tcp               # optional, default: tcp
        source: 192.168.1.0/24      # optional, restrict source IP
  ipv6:
    allowed_ports:
      - port: 22
```

Default policy is **drop** for FORWARD and **accept** for OUTPUT. INPUT rejects unmatched packets with ICMP port-unreachable.
