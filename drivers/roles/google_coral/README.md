# google-coral

Installs the Google Coral M.2 Edge TPU driver and runtime. If k3s is present, labels the node with `hardware/coral-tpu=true` for pod scheduling.

## Variables

```yaml
google_coral:
  runtime: std             # "std" (reduced clock) or "max" (maximum performance)
```

## What It Does

1. Adds the Coral apt repository and GPG key
2. Installs `gasket-dkms` (PCIe driver) and `libedgetpu1-std/max` (runtime)
3. Creates udev rule for `/dev/apex_*` devices
4. Creates `apex` group for non-root device access
5. If k3s is installed, labels the node for workload scheduling

## Kubernetes Scheduling

Use a `nodeSelector` to target Coral nodes:

```yaml
nodeSelector:
  hardware/coral-tpu: "true"
```
