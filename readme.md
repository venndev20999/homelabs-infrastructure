# Homelabs Infrastructure

This repository defines the complete "Infrastructure as Code" (IaC) foundation for the **Finance Stock** project. From physical/KVM hardware provisioning to the Kubernetes cluster and application services.

---

## 🏗 High-Level Architecture

The infrastructure is split into two main layers:

1.  **Standalone VMs (Ansible Managed):**
    Services like **PostgreSQL**, **Elasticsearch**, and **Kafka-Connect** run on dedicated standalone Ubuntu VMs provisioned on a **Cockpit KVM Host** (localserver).
2.  **Kubernetes Cluster (Talos + Terraform Managed):**
    A high-performance cluster running on **Talos Linux** nodes. This hosts our containerized applications, managed through **Terraform**.

---

## 🚀 Step-by-Step Provisioning Guide

Follow this sequence to bootstrap the environment from scratch.

### Phase 1: Bare-metal & VM Foundation (Ansible)
Use Ansible to create the virtual machines on your KVM host.
1.  **Environment Setup**: Follow the [Ansible README](./ansible-provisioner/README.md) to set up your `uv` environment.
2.  **Create VMs**:
    ```bash
    cd ansible-provisioner
    ansible-playbook -i inventories/dev/inventory.ini playbooks/create-talos-cluster.yml
    ```
3.  **Bootstrap Common Baseline**:
    Configure SSH, timezone, and security for all standalone nodes:
    ```bash
    ansible-playbook -i inventories/dev/inventory.ini playbooks/common.yml
    ```

### Phase 2: Kubernetes Cluster (Terraform + Talos)
Once the VMs are booted into Talos Maintenance mode:
1.  **Init & Apply**:
    ```bash
    cd k8s/terraform
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
- **Cilium CNI**: For networking and security.
- **MetalLB**: For external LoadBalancer IPs.

### Phase 4: Application Services (Ansible / K8s)
- **Standalone DBs**: Provision Postgres/Elasticsearch using:
  ```bash
  ansible-playbook -i inventories/dev/inventory.ini playbooks/elasticsearch.yml
  ```
- **K8s Apps**: Deploy Kubernetes manifests through the `k8s/` directory.

---

## 📁 Infrastructure Components

| Directory | Responsibility | Tools |
| :-- | :-- | :-- |
| [`ansible-provisioner/`](./ansible-provisioner/README.md) | **Foundation**: VM Creation, Patching, Standalone Services | Ansible, Libvirt, Python (uv) |
| [`k8s/`](./k8s/readme.md) | **Platform**: Kubernetes Cluster & Internal Addons | Talos Linux, Terraform, Helm |
| `postgres/`, `elasticsearch/` | **Standalone Apps**: Detailed configs for each service | Ansible |
| `cloudflared/` | **Connectivity**: Tunneling for external access | Docker, Cloudflare |

---

## 🛡 Features & Capabilities

- **Immutable Infrastructure**: K8s nodes run Talos Linux (no SSH, API-managed).
- **Environment Isolation**: Separate `dev` and `prd` inventories and Terraform states.
- **Automatic Health Checks**: Built-in Ansible/K8s checks to monitor node/service health.
- **Unified Management**: Python dependencies managed with `uv` for speed and consistency.
- **GitOps Ready**: Infrastructure that is entirely versioned and reproducible.
