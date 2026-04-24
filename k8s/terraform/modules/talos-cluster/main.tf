# Generate Machine Secrets
resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = var.controlplane_ips
}

# Generate Controlplane Config
data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version

  docs     = false
  examples = false

  # Patch: Disable Default CNI and Kube-Proxy for Cilium CNI installation
  config_patches = [
    yamlencode({
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
        # Fix: Grant API Server permission to talk to Kubelets
        inlineManifests = [
          {
            name = "kube-apiserver-to-kubelet-rbac"
            contents = yamlencode({
              apiVersion = "rbac.authorization.k8s.io/v1"
              kind       = "ClusterRoleBinding"
              metadata = {
                name = "system:kube-apiserver-to-kubelet"
              }
              roleRef = {
                apiGroup = "rbac.authorization.k8s.io"
                kind       = "ClusterRole"
                name       = "system:kube-apiserver-to-kubelet"
              }
              subjects = [
                {
                  apiGroup = "rbac.authorization.k8s.io"
                  kind       = "User"
                  name       = "apiserver-kubelet-client"
                }
              ]
            })
          }
        ]
      }
    })
  ]
}

# Generate Worker Config
data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version

  docs     = false
  examples = false
}

# Apply Controlplane Config
resource "talos_machine_configuration_apply" "controlplane" {
  count                       = length(var.controlplane_ips)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = var.controlplane_ips[count.index]
}

# Apply Worker Config
resource "talos_machine_configuration_apply" "worker" {
  count                       = length(var.worker_ips)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = var.worker_ips[count.index]
}

# Bootstrap the cluster on the first master node
resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.controlplane_ips[0]
}

# Extract the cluster Kubeconfig
resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.controlplane_ips[0]
}

# ── Write configs to local files ───────────────────────────────────────────────
resource "local_file" "talosconfig" {
  content         = data.talos_client_configuration.this.talos_config
  filename        = "${path.root}/output/talosconfig"
  file_permission = "0600"
}

resource "local_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = "${path.root}/output/kubeconfig"
  file_permission = "0600"
}

# ── Wait for cluster to be healthy before helm ───────────────────────────────────
data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_bootstrap.this,
    helm_release.cilium
  ]

  client_configuration   = talos_machine_secrets.this.client_configuration
  control_plane_nodes    = var.controlplane_ips
  endpoints              = var.controlplane_ips
  skip_kubernetes_checks = true # Allow Cilium to be installed while nodes are NotReady
}

# ── Install Gateway API CRDs ───────────────────────────────────────────────────
# Required for Cilium Gateway API support
resource "helm_release" "gateway_api_crds" {
  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]

  name             = "gateway-api-crds"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "gateway-api"
  version          = "0.1.0" # Version of the CRD chart
  namespace        = "kube-system"
  create_namespace = false
}

# ── Deploy Cilium CNI ──────────────────────────────────────────────────────────
# Deploys Cilium automatically into the cluster after it is bootstrapped.
# Based on: https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium
resource "helm_release" "cilium" {
  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this,
    helm_release.gateway_api_crds
  ]

  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.15.5" # Use stable version matching your k8s/talos setup
  namespace  = "kube-system"

  values = [
    yamlencode({
      ipam = {
        mode = "kubernetes"
      }
      kubeProxyReplacement = true
      securityContext = {
        capabilities = {
          ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
          cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
        }
      }
      cgroup = {
        autoMount = {
          enabled = false
        }
        hostRoot = "/sys/fs/cgroup"
      }
      k8sServiceHost = "localhost"
      k8sServicePort = 7445
      gatewayAPI = {
        enabled = true
      }
      ingressController = {
        enabled = true
        loadbalancer = {
          annotation = true
        }
      }
      l2announcements = {
        enabled = true
      }
      externalIPs = {
        enabled = true
      }
    })
  ]
}
