# Kubernetes Infrastructure — Talos + Terraform

This directory contains infrastructure-as-code for deploying and managing the Talos Kubernetes cluster for the Finance Stock project.

## Architecture

| Component | Tool | Details |
|---|---|---|
| OS | [Talos Linux](https://www.talos.dev/) | Immutable, API-driven OS purpose-built for k8s |
| Provisioning | [Terraform](https://www.terraform.io/) | Configures cluster via Talos provider (mTLS, no SSH) |
| VM Host | Cockpit / KVM (localserver) | VMs run on `192.168.122.x` libvirt default network |
| CNI | [Cilium](https://cilium.io/) | Default CNI and kube-proxy disabled in Talos config |

## Directory Structure

```
terraform/
├── Makefile                        ← All commands live here
├── environments/
│   ├── dev/
│   │   ├── main.tf                 ← Module wiring
│   │   ├── variables.tf
│   │   ├── terraform.tfvars        ← Node IPs (edit this per environment)
│   │   ├── providers.tf
│   │   ├── outputs.tf
│   │   └── output/                 ← Generated after apply (gitignored)
│   │       ├── kubeconfig
│   │       └── talosconfig
│   ├── staging/
│   └── prod/
└── modules/
    └── talos-cluster/              ← Reusable module (secrets, config, bootstrap)
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

## Prerequisites

- Docker installed locally (Terraform runs in `hashicorp/terraform:light`)
- VMs provisioned via Ansible (`singles/create-talos-server.yml`)  
- VMs booted from Talos ISO and in **Maintenance mode** (reachable on port `50000`)
- Run commands from `infrastructure/k8s/terraform/` directory

## How Authentication Works

Terraform communicates with Talos nodes via **mutual TLS on port 50000** — no SSH, no password needed.

```
terraform apply
  │
  ├─► talos_machine_secrets     — generates PKI certs + cluster join token
  ├─► talos_machine_configuration — embeds certs into machine config YAML
  ├─► talos_machine_configuration_apply — pushes config to each node :50000 (mTLS)
  ├─► talos_machine_bootstrap   — bootstraps etcd on first control plane
  └─► talos_cluster_kubeconfig  — retrieves kubeconfig from cluster
```

## Deploy Commands

All commands run from `infrastructure/k8s/terraform/`:

```bash
# ── Bootstrap ──────────────────────────────────────────────────────
make dev init          # Download providers (siderolabs/talos, hashicorp/local)
make dev validate      # Validate HCL syntax
make dev fmt           # Format all .tf files

# ── Deploy ─────────────────────────────────────────────────────────
make dev plan          # Preview changes → saves tfplan file
make dev apply         # Deploy cluster (auto-approve)
make dev apply-plan    # Apply from previously saved plan

# ── Credentials ────────────────────────────────────────────────────
make dev kubeconfig    # Save kubeconfig  → environments/dev/output/kubeconfig
make dev talosconfig   # Save talosconfig → environments/dev/output/talosconfig

# ── Inspect ────────────────────────────────────────────────────────
make dev output        # Show all terraform outputs
make dev state-list    # List managed resources in state
make dev refresh       # Sync state with real infrastructure
make dev console       # Interactive terraform console

# ── Teardown ───────────────────────────────────────────────────────
make dev destroy       # Destroy cluster (auto-approve)
```

## Full Deployment Flow

```bash
cd infrastructure/k8s/terraform

# Step 1: Provision VMs (from ansible-provisioner/)
ansible-playbook -i ../ansible-provisioner/src/inventory.ini \
  ../ansible-provisioner/src/singles/create-talos-server.yml

# Step 2: Init Terraform
make dev init

# Step 3: Preview
make dev plan

# Step 4: Deploy Talos cluster
make dev apply

# Step 5: Save credentials
make dev kubeconfig
make dev talosconfig

# Step 6: Verify
export KUBECONFIG=$(pwd)/environments/dev/output/kubeconfig
export TALOSCONFIG=$(pwd)/environments/dev/output/talosconfig

kubectl get nodes
talosctl --nodes 192.168.122.110 get members
```

## Accessing from Mac (via localserver)

VMs are on `192.168.122.x` (libvirt NAT) — not directly reachable from your Mac.

**Option 1 — Run Terraform on localserver (recommended):**
```bash
rsync -av . localserver:~/terraform-talos/
ssh localserver
cd ~/terraform-talos && make dev apply
```

**Option 2 — SOCKS proxy from Mac:**
```bash
ssh -D 1080 -N vennpham@localserver &
export HTTPS_PROXY=socks5://localhost:1080
make dev apply
```

## Environment Configuration

Edit `environments/<env>/terraform.tfvars` to change node IPs:

```hcl
cluster_name     = "finance-k8s-dev"
cluster_endpoint = "https://192.168.122.110:6443"
talos_version    = "v1.7.0"

controlplane_ips = ["192.168.122.110"]
worker_ips       = [
  "192.168.122.111",
  "192.168.122.112",
  "192.168.122.113",
  "192.168.122.114"
]
```

## After Cluster is Running

```bash
# Check nodes
kubectl get nodes -o wide

# Install Cilium CNI (required — default CNI is disabled)
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system \
  --set kubeProxyReplacement=true

# Check Talos node health
talosctl --nodes 192.168.122.110 health
talosctl --nodes 192.168.122.110 dashboard

# Upgrade Talos OS
talosctl --nodes 192.168.122.110 upgrade --image ghcr.io/siderolabs/installer:v1.7.1
```
