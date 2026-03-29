# Homelabs Infrastructure

This repository defines the complete "Infrastructure as Code" (IaC) foundation for the **Finance Stock** project. From physical/KVM hardware provisioning to the Kubernetes cluster and application services.

---

## ⚡️ Key Features

*   **🚀 15-Minute Zero-to-Cluster:** Go from an empty KVM host to a fully functional Kubernetes cluster in under 15 minutes.
*   **🛠 Full Ansible VM Provisioning:** Automated creation of control-plane and worker VMs with static DHCP assignments and resource tuning.
*   **🛡 Immutable Infrastructure:** Kubernetes nodes run **Talos Linux** — a security-hardened, API-managed OS with no SSH and no shell.
*   **🌍 Multi-Environment Ready:** Native support for `dev`, `staging`, and `prd` through directory-based inventory and Terraform variable isolation.
*   **End-to-End Automation:** A unified workflow that bridges Python dependencies (`uv`), Ansible (VMs), and Terraform (K8s).

---

## 🏗 High-Level Architecture

The infrastructure is split into two main layers:

1.  **Standalone VMs (Ansible Managed):**
    Services like **PostgreSQL**, **Elasticsearch**, and **Kafka-Connect** run on dedicated standalone Ubuntu VMs provisioned on a **Cockpit KVM Host** (localserver).
2.  **Kubernetes Cluster (Talos + Terraform Managed):**
    A high-performance cluster running on **Talos Linux** nodes. This hosts our containerized applications, managed through **Terraform**.

---

## 🚀 Step-by-Step Provisioning Guide

Follow this sequence for the fastest deployment from scratch.

### Phase 1: Bare-metal & VM Foundation (Ansible)
Use Ansible to create the virtual machines on your KVM host.
1.  **Environment Setup**: Follow the [Ansible README](./ansible-provisioner/README.md) to set up your `uv` environment.
2.  **Create VMs**:
    ```bash
    cd ansible-provisioner
    # (~3 mins) This creates 5 VMs with networking on the host host
    ansible-playbook -i inventories/dev/inventory.ini playbooks/create-talos-cluster.yml
    ```
3.  **Bootstrap Common Baseline**:
    ```bash
    ansible-playbook -i inventories/dev/inventory.ini playbooks/common.yml
    ```

### Phase 2: Kubernetes Cluster (Terraform + Talos)
Once the VMs are booted into Talos Maintenance mode:
1.  **Init & Apply**:
    ```bash
    cd k8s/terraform
    # (~10 mins) Pulls providers, configures talos nodes, and bootstraps k8s
    make dev init
    make dev apply
    ```
2.  **Extract Kubeconfig**:
    ```bash
    make dev kubeconfig
    export KUBECONFIG=$(pwd)/environments/dev/output/kubeconfig
    ```

### Phase 3: Infrastructure Addons (Terraform / Helm)
The `talos-cluster` module automatically installs:
- **Cilium CNI**: Networking with eBPF and security policies.
- **MetalLB**: Layer 2 advertisement for LoadBalancer services on your local network.

---

## 📁 Infrastructure Components

| Directory | Responsibility | Tools |
| :-- | :-- | :-- |
| [`ansible-provisioner/`](./ansible-provisioner/README.md) | **Foundation**: VM Creation, Patching, Standalone Services | Ansible, Libvirt, Python (uv) |
| [`k8s/`](./k8s/readme.md) | **Platform**: Kubernetes Cluster & Internal Addons | Talos Linux, Terraform, Helm |
| `postgres/`, `elasticsearch/` | **Standalone Apps**: Detailed configs for each service | Ansible |
| `cloudflared/` | **Connectivity**: Tunneling for external access | Docker, Cloudflare |

---

## 🛡 Capabilities

- **Automatic Health Checks**: Built-in Ansible tasks to monitor disk and service health.
- **Unified Management**: Fast Python management with `uv`.
- **GitOps Ready**: Every piece of infrastructure is versioned and trackable.
