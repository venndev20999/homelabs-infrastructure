# ☸️ Kubernetes (k8s) Infrastructure — Homelabs

This directory is the central hub for our Kubernetes ecosystem. We use **Talos Linux** for an immutable, security-focused base and **Terraform** for automated cluster lifecycle management.

---

## 🏗 High-Level Architecture

| Layer | Component | Description |
| :--- | :--- | :--- |
| **Operating System** | [Talos Linux](https://www.talos.dev/) | API-managed, immutable OS. No SSH, no shell, reduced attack surface. |
| **Provisioning** | [Terraform](./terraform/readme.md) | Manages machine configuration, cluster bootstrap, and credentials via mTLS. |
| **Networking** | [Cilium](https://cilium.io/) | Advanced CNI with eBPF, replacing kube-proxy for high performance. |
| **Load Balancing** | MetalLB | Provides internal LoadBalancer IPs on the `192.168.122.x` network. |
| **Infrastructure Host** | Cockpit / KVM | All nodes run as virtual machines on the `localserver` host. |

---

## 📂 Directory Structure

*   **[`terraform/`](./terraform/readme.md)**: Terraform modules and environment configurations (dev/staging/prod).
*   **[`helm/`](./helm/)**: Custom Helm chart values and deployment scripts for cluster addons.
*   `create-cluster.sh`: A legacy/utility script for manual VM provisioning on the KVM host (now largely replaced by Ansible).

---

## 🚀 Deployment Workflow

To get the cluster up and running, follow these steps:

### 1. Provision VMs (Ansible)
Before running Terraform, the bare VMs must be created on the KVM host.
```bash
# From the project root
cd ansible-provisioner
ansible-playbook -i inventories/dev/inventory.ini playbooks/create-talos-cluster.yml
```

### 2. Bootstrap Cluster (Terraform)
Once VMs are in Maintenance mode, apply the Talos configuration.
```bash
cd k8s/terraform
make dev init
make dev apply
```

### 3. Access the Cluster
Retrieve your credentials and verify node status.
```bash
make dev kubeconfig
export KUBECONFIG=$(pwd)/environments/dev/output/kubeconfig

kubectl get nodes -o wide
```

---

## 🛠 Cluster Operations

### Common Talos Commands
Since there is no SSH, use `talosctl` for node management:
```bash
# Check node health
talosctl --nodes <IP> health

# View real-time dashboard
talosctl --nodes <IP> dashboard

# Upgrade Talos OS
talosctl --nodes <IP> upgrade --image ghcr.io/siderolabs/installer:v1.7.5
```

### Resource Dashboard (Static IP Reference)
*Standard allocations in the `192.168.122.x` range:*
- **Control Plane**: `192.168.122.110` (Virtual Endpoint)
- **Workers**: `192.168.122.111` through `114`
- **Ingress/LB Pool**: `192.168.122.200` to `250`

---

## 📒 Manual / Troubleshooting
If you need to manually assign a DHCP reservation for a new node on the KVM host:
```bash
# Assign static IP to a MAC address
virsh net-update default add ip-dhcp-host \
  --xml "<host mac='52:54:00:xx:xx:xx' name='new-node' ip='192.168.122.xxx'/>" \
  --live --config
```
