# Create namespace for ArgoCD
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Secret containing the Age Private Key for ArgoCD SOPS decryption
resource "kubernetes_secret_v1" "sops_age" {
  depends_on = [
    kubernetes_namespace_v1.argocd
  ]

  metadata {
    name      = "sops-age"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  data = {
    "key.txt" = var.sops_age_key
  }

  type = "Opaque"
}

# Deploy ArgoCD via Helm
resource "helm_release" "argocd" {
  depends_on = [
    kubernetes_namespace_v1.argocd,
    kubernetes_secret_v1.sops_age
  ]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      configs = merge(
        {
          params = {
            "server.insecure" = true
          }
        },
        var.argocd_admin_password != "" ? {
          secret = {
            # Hashed password for admin user
            argocdAdminPassword = var.argocd_admin_password
          }
        } : {},
        var.github_client_id != "" && var.github_client_secret != "" ? {
          cm = {
            url = "http://argocd.vennpham.local"
            "dex.config" = yamlencode({
              connectors = [
                {
                  type = "github"
                  id   = "github"
                  name = "GitHub"
                  config = {
                    clientID     = var.github_client_id
                    clientSecret = var.github_client_secret
                  }
                }
              ]
            })
          }
          rbac = {
            "policy.default" = ""
            "policy.csv" = join("\n", concat(
              [
                "p, role:readonly, *, get, *, allow",
                "p, role:readonly, applications, sync, *, allow"
              ],
              [for email in var.admin_users : "g, ${email}, role:admin"],
              [for email in var.developer_users : "g, ${email}, role:readonly"]
            ))
          }
        } : {}
      )
      controller = {
        metrics = {
          enabled = true
          service = {
            annotations = {
              "prometheus.io/scrape" = "true"
              "prometheus.io/port"   = "8082"
            }
          }
        }
      }
      dex = {
        metrics = {
          enabled = true
          service = {
            annotations = {
              "prometheus.io/scrape" = "true"
              "prometheus.io/port"   = "5557"
            }
          }
        }
      }
      repoServer = {
        metrics = {
          enabled = true
          service = {
            annotations = {
              "prometheus.io/scrape" = "true"
              "prometheus.io/port"   = "8084"
            }
          }
        }
        env = [
          {
            name  = "HELM_PLUGINS"
            value = "/custom-tools/helm-plugins/helm-secrets"
          },
          {
            name  = "HELM_SECRETS_SOPS_PATH"
            value = "/custom-tools/sops"
          },
          {
            name  = "HELM_SECRETS_HELM_PATH"
            value = "/usr/local/bin/helm"
          },
          {
            name  = "SOPS_AGE_KEY_FILE"
            value = "/helm-secrets-private-keys/key.txt"
          }
        ]
        volumes = [
          {
            name     = "custom-tools"
            emptyDir = {}
          },
          {
            name = "helm-secrets-private-keys"
            secret = {
              secretName = "sops-age"
            }
          }
        ]
        volumeMounts = [
          {
            name      = "custom-tools"
            mountPath = "/custom-tools"
          },
          {
            name      = "custom-tools"
            subPath   = "helm"
            mountPath = "/usr/local/sbin/helm"
          },
          {
            name      = "helm-secrets-private-keys"
            mountPath = "/helm-secrets-private-keys"
            readOnly  = true
          }
        ]
        initContainers = [
          {
            name            = "download-tools"
            image           = "alpine:3.20"
            imagePullPolicy = "IfNotPresent"
            command         = ["sh", "-ec"]
            args = [
              <<-EOT
              mkdir -p /custom-tools/helm-plugins
              wget -O /custom-tools/sops https://github.com/getsops/sops/releases/download/v3.9.0/sops-v3.9.0.linux.amd64
              chmod +x /custom-tools/sops
              wget -qO- https://github.com/jkroepke/helm-secrets/releases/download/v4.6.0/helm-secrets.tar.gz | tar -C /custom-tools/helm-plugins -xzf-
              cp /custom-tools/helm-plugins/helm-secrets/scripts/wrapper/helm.sh /custom-tools/helm
              chmod +x /custom-tools/helm
              EOT
            ]
            volumeMounts = [
              {
                name      = "custom-tools"
                mountPath = "/custom-tools"
              }
            ]
          }
        ]
      }
      server = {
        metrics = {
          enabled = true
          service = {
            annotations = {
              "prometheus.io/scrape" = "true"
              "prometheus.io/port"   = "8083"
            }
          }
        }
      }
    })
  ]
}

# ── Create Namespace for Envoy Gateway ──────────────────────────────────────────
resource "kubernetes_namespace_v1" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
  }
}

# Deploy Envoy Gateway (Gateway API controller) via OCI Helm chart
resource "helm_release" "envoy_gateway" {
  depends_on = [
    kubernetes_namespace_v1.envoy_gateway_system
  ]

  name       = "envoy-gateway"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-helm"
  version    = "v1.1.0"
  namespace  = "envoy-gateway-system"
}

# ── Create Namespace for MetalLB ──────────────────────────────────────────────
# The namespace must be explicitly created and labeled as "privileged" to satisfy PodSecurity standards,
# as MetalLB speaker pods run hostNetwork, hostPorts, and require capabilities like NET_ADMIN.
resource "kubernetes_namespace_v1" "metallb_system" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Deploy MetalLB via Helm
resource "helm_release" "metallb" {
  depends_on = [
    kubernetes_namespace_v1.metallb_system
  ]

  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.14.8"
  namespace  = "metallb-system"
}

# Apply MetalLB Configuration (IPAddressPool and L2Advertisement)
resource "terraform_data" "metallb_config" {
  depends_on = [
    helm_release.metallb
  ]

  input = var.kubeconfig_path

  triggers_replace = [
    filemd5("${path.module}/../../../metallb-config.yaml")
  ]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig ${var.kubeconfig_path} apply -f ${path.module}/../../../metallb-config.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig ${self.input} delete -f ${path.module}/../../../metallb-config.yaml --ignore-not-found"
  }
}

# ── Create Namespace for Local Path Provisioner ───────────────────────────────
# The namespace must be explicitly created and labeled as "privileged" because the provisioner helper pods
# mount node host paths (/opt/local-path-provisioner) to create and manage local persistent directories.
resource "kubernetes_namespace_v1" "local_path_storage" {
  metadata {
    name = "local-path-storage"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Deploy Rancher Local Path Provisioner via raw manifests (Official installation method)
resource "terraform_data" "local_path_provisioner" {
  depends_on = [
    kubernetes_namespace_v1.local_path_storage
  ]

  input = var.kubeconfig_path

  provisioner "local-exec" {
    command = "kubectl --kubeconfig ${var.kubeconfig_path} apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml"
  }

  # Set local-path StorageClass as default
  provisioner "local-exec" {
    command = "kubectl --kubeconfig ${var.kubeconfig_path} annotate storageclass local-path storageclass.kubernetes.io/is-default-class=true --overwrite"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig ${self.input} delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml --ignore-not-found"
  }
}
