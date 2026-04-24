# ── Cilium Networking (1-Click Provisioning) ──────────────────────────────────
# Using null_resource + kubectl to bypass Terraform's plan-time CRD validation.
# This ensures a smooth 1-click apply even when CRDs are newly installed.

resource "null_resource" "cilium_networking" {
  depends_on = [helm_release.cilium]

  triggers = {
    # Re-run if the manifest content changes
    manifest_hash = sha256(local.networking_manifests)
  }

  provisioner "local-exec" {
    command = "echo '${local.networking_manifests}' | KUBECONFIG=${path.root}/output/kubeconfig kubectl apply -f -"
  }
}

locals {
  networking_manifests = <<EOT
---
# Cilium LoadBalancer IP Pool
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "homelab-pool"
spec:
  blocks:
    - cidr: "192.168.122.200/29"
---
# Cilium L2 Announcement Policy
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: "l2-policy"
spec:
  loadBalancerIPs: true
  interfaces:
    - "^enp.*"
  nodeSelector:
    matchLabels:
      kubernetes.io/os: linux
---
# Default Gateway
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: default
spec:
  gatewayClassName: cilium
  listeners:
  - name: http-work
    protocol: HTTP
    port: 80
    hostname: "*.vennpham.work"
    allowedRoutes:
      namespaces:
        from: All
  - name: http-local
    protocol: HTTP
    port: 80
    hostname: "*.vennpham.local"
    allowedRoutes:
      namespaces:
        from: All
EOT
}
