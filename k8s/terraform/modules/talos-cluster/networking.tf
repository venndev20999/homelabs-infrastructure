locals {
  # We use a single YAML manifest for all Cilium and Gateway API resources.
  # This ensures a smooth 1-click apply even when CRDs are newly installed.

  networking_manifests = <<EOT
---
apiVersion: v1
kind: Namespace
metadata:
  name: test-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: test-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-svc
  namespace: test-app
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
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
apiVersion: cilium.io/v2alpha1
kind: CiliumLoadBalancerIPPool
metadata:
  name: "homelab-pool"
spec:
  cidrs:
    - cidr: "192.168.122.200/29"
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: "l2-policy"
spec:
  loadBalancerIPs: true
  interfaces:
    - "^en.*"
  nodeSelector:
    matchExpressions:
      - key: node-role.kubernetes.io/control-plane
        operator: DoesNotExist
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
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: default
spec:
  gatewayClassName: eg
  listeners:
  - name: http-work
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
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

resource "null_resource" "cilium_networking" {
  depends_on = [
    helm_release.cilium,
    helm_release.envoy_gateway
  ]

  triggers = {
    # Re-run if the manifest content changes
    manifest_hash = sha256(local.networking_manifests)
  }

  provisioner "local-exec" {
    # Apply the combined manifest using kubectl
    command = "export KUBECONFIG=${path.root}/output/kubeconfig && echo '${local.networking_manifests}' | $(command -v kubectl || echo kubectl) apply -f - --validate=false"
  }

  # Add a destroy provisioner to clean up resources if needed
  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "KUBECONFIG=${path.root}/output/kubeconfig echo '${local.networking_manifests}' | $(command -v kubectl || echo kubectl) delete -f - --ignore-not-found"
  # }
}
