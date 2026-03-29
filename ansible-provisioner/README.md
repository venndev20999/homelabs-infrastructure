# Ansible Provisioner

This directory contains the Ansible playbooks and configurations used to provision, patch, and manage infrastructure nodes for the **Finance Stock** project.

## 🛠 Prerequisites & Environment Setup

This project uses [uv](https://github.com/astral-sh/uv) to manage a fast, isolated Python environment.

### 1. Install `uv` (if not already installed)
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2. Prepare Virtual Environment
Run these commands from the `infrastructure/ansible-provisioner/` directory:
```bash
# Create the virtual environment
uv venv

# Activate the environment
source .venv/bin/activate

# Install Ansible and dependencies
uv pip install ansible
```

---

## 📂 Directory Structure

```text
ansible-provisioner/
├── README.md             ← This documentation
├── inventories/          ← Environment-specific inventories
│   ├── dev/              ← Development nodes (local KVM)
│   └── prd/              ← Production nodes
├── modules/              # Reusable task modules (Roles)
├── playbooks/            # Entrance playbooks for specific tasks
└── vars/                 # Shared variables
```

---

## 🚀 Usage & Commands

All commands should be run from the `infrastructure/ansible-provisioner/` root directory.

### 1. Provision Talos Kubernetes Cluster VMs
Connects to the KVM `localserver` host to provision VMs via `virt-install`.
```bash
ansible-playbook -i inventories/dev/inventory.ini playbooks/create-talos-cluster.yml -e "talos_prefix=dev"
```

### 2. Apply Common Server Configurations
Applies baseline settings (SSH hardening, users, timezone) across standalone servers.
```bash
ansible-playbook -i inventories/dev/inventory.ini playbooks/common.yml
```
> **Tip:** Limit execution using `-l`: `ansible-playbook -i inventories/dev/inventory.ini playbooks/common.yml -l elasticsearch`

### 3. Service-Specific Provisioning
Deploy standalone services like Elasticsearch onto provisioned VMs:
```bash
ansible-playbook -i inventories/dev/inventory.ini playbooks/elasticsearch.yml
```

### 4. Patching and Updates
Runs system upgrades (`apt update && apt upgrade`) across all Linux servers.
```bash
ansible-playbook -i inventories/dev/inventory.ini playbooks/patching.yml
```

### 5. Health Checks
Verifies disk space, service status, and connectivity.
```bash
ansible-playbook -i inventories/dev/inventory.ini playbooks/healthcheck.yml
```

---

## 🔄 Workflow Reminder

When adding new servers:
1. Update your inventory file (e.g., `inventories/dev/inventory.ini`) with the new host/IP.
2. Run `playbooks/common.yml` on the new host to bootstrap it into management.
3. Run the specific service playbook (e.g., `playbooks/elasticsearch.yml`) if needed.
