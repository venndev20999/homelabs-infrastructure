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
    command = "KUBECONFIG=${path.root}/output/kubeconfig $(command -v kubectl || echo kubectl) apply -f - <<EOF\n${local.networking_manifests}\nEOF"
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
  serviceSelector:
    matchLabels: {} # Match all services
---
# Cilium L2 Announcement Policy
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: "l2-policy"
spec:
  loadBalancerIPs: true
  interfaces:
    - "^en.*"
  nodeSelector:
    matchLabels:
      kubernetes.io/os: linux
  serviceSelector:
    matchLabels: {} # Match all services
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
---
# Default Gateway
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: default
spec:
  gatewayClassName: eg
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
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-from-default
  namespace: test-app
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: default
  to:
  - group: ""
    kind: Service
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: nginx-test-route
  namespace: default
spec:
  parentRefs:
  - name: main-gateway
    namespace: default
  hostnames:
  - "test.vennpham.work"
  - "test.vennpham.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx-test-svc
      namespace: test-app
      port: 80
EOT
}
