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

  # Patch: Disable Default CNI (and optionally Kube-Proxy if using Cilium)
  config_patches = concat(
    [
      yamlencode({
        cluster = {
          network = {
            cni = {
              name = "none"
            }
          }
        }
      })
    ],
    var.cni == "cilium" ? [
      yamlencode({
        cluster = {
          proxy = {
            disabled = true
          }
        }
      })
    ] : []
  )
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
# data "talos_cluster_health" "this" {
#   depends_on = [
#     talos_machine_configuration_apply.controlplane,
#     talos_machine_bootstrap.this
#   ]

#   client_configuration = talos_machine_secrets.this.client_configuration
#   control_plane_nodes  = var.controlplane_ips
#   endpoints            = var.controlplane_ips
#   skip_kubernetes_checks = true
# }

# ── Deploy Cilium CNI ──────────────────────────────────────────────────────────
# Deploys Cilium automatically into the cluster after it is bootstrapped.
# Based on: https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium
resource "helm_release" "cilium" {
  count = var.cni == "cilium" ? 1 : 0

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this,
    # data.talos_cluster_health.this
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
    })
  ]
}

# ── Deploy Calico CNI ──────────────────────────────────────────────────────────
# Deploys Calico automatically into the cluster after it is bootstrapped.
# Based on: https://docs.tigera.io/calico/latest/getting-started/kubernetes/helm
resource "helm_release" "calico" {
  count = var.cni == "calico" ? 1 : 0

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this,
    # data.talos_cluster_health.this
  ]

  name             = "calico"
  repository       = "https://docs.tigera.io/calico/charts"
  chart            = "tigera-operator"
  version          = "v3.32.1"
  namespace        = "tigera-operator"
  create_namespace = true

  values = [
    yamlencode({
      installation = {
        enabled            = true
        kubernetesProvider = ""
        cni = {
          type = "Calico"
          ipam = {
            type = "Calico"
          }
        }
        calicoNetwork = {
          bgp = "Disabled"
          ipPools = [
            {
              cidr          = "10.244.0.0/16"
              encapsulation = "VXLAN"
              natOutgoing   = "Enabled"
              nodeSelector  = "all()"
              blockSize     = 26
            }
          ]
        }
      }
      defaultFelixConfiguration = {
        enabled      = true
        cgroupV2Path = "/sys/fs/cgroup"
      }
    })
  ]
}
