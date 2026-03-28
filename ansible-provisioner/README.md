# Ansible Provisioner

This directory contains the Ansible playbooks and configurations used to provision, patch, and manage infrastructure nodes for the **Finance Stock** project.

## Directory Structure

```text
ansible-provisioner/
├── README.md             ← This documentation
└── src/
    ├── inventory.ini     ← Host inventory definition (localserver, talos, db, etc.)
    ├── ansible.cfg       ← Ansible base configuration
    ├── vars/             ← Environment variable files (e.g., talos-dev.yml)
    ├── modules/          ← Reusable task files
    └── singles/          ← Entrypoint playbooks ready to run
```

## Usage & Commands

All commands below should be run from the `infrastructure/ansible-provisioner/src/` directory to ensure `inventory.ini` and `ansible.cfg` are loaded correctly.

```bash
cd infrastructure/ansible-provisioner/src
```

### 1. Provision Talos Kubernetes Cluster VMs
Connects to the KVM `localserver` host to provision VMs via `virt-install`, waits for them to boot, and registers their MAC addresses to static IPs using `virsh net-update` (DHCP).

```bash
ansible-playbook -i inventory.ini singles/create-talos-server.yml -e "talos_prefix=dev"
```

### 2. Apply Common Server Configurations
Applies baseline settings across all defined standalone servers (like `docker-server`, `elasticsearch01`, `postgres`, etc.). Typically sets up users, SSH keys, timezone, bash profiles, or standard packages.

```bash
ansible-playbook -i inventory.ini singles/common.yml
```
> **Tip:** You can limit execution to a specific host group using `-l`:
> ```bash
> ansible-playbook -i inventory.ini singles/common.yml -l databases
> ```

### 3. Patching and Updates
Runs system package updates (e.g., `apt update && apt upgrade`) and manages automated reboots across Linux servers if required after an update.

```bash
ansible-playbook -i inventory.ini singles/patching.yml
```

### 4. Storage & Disk Mounting
Configures and mounts secondary volumes/disks on VMs exactly as defined, setting up LVM, formatting partitions, and updating `/etc/fstab` for persistence across reboots.

```bash
ansible-playbook -i inventory.ini singles/mount.yml
```

### 5. Health Checks
Verifies the running services, disk spaces, and connectivity for host infrastructure before or after deployments.

```bash
ansible-playbook -i inventory.ini singles/healthcheck.yml
```

## Workflow Reminder

When adding new servers:
1. Update `src/inventory.ini` with the new host/IP.
2. (Optional) Document IP allocation to prevent collisions.
3. Run `singles/common.yml` on the new host to bootstrap it into management.
