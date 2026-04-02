# ─────────────────────────────────────────────────────────────────────────────
# Homelab Infrastructure Root Makefile
# Usage:
#   make create vm vm_prefix=... vm_ip=...
#   make create talos-cluster talos_prefix=... [args...]
# ─────────────────────────────────────────────────────────────────────────────

# ── Config ────────────────────────────────────────────────────────────────────
VM_METADATA_FILE = vm.json
ANSIBLE_DIR      = ansible-provisioner
TF_K8S_DIR       = k8s/terraform
SSH_CONFIG       = sshconfig

.PHONY: create vm talos-cluster metadata update-metadata help

# ── Main Entry Points ─────────────────────────────────────────────────────────

# Entry point for creation (acts as a namespace)
create:
	@:

# Command: create vm
# Example: make create vm vm_prefix=redis-2 vm_ip=192.168.122.12 vm_cpu=2 vm_mem=2048
vm:
	@if [ -z "$(vm_prefix)" ]; then echo "Error: vm_prefix is required"; exit 1; fi
	@echo "🚜 [ansible] Provisioning standalone VM: $(vm_prefix)"
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini \
		playbooks/create-vm-server.yml \
		-e "vm_prefix=$(vm_prefix)" \
		-e "vm_ip=$(vm_ip)" \
		-e "vm_cpu=$(vm_cpu)" \
		-e "vm_mem=$(vm_mem)"
	@$(MAKE) update-metadata NAME="vm-$(vm_prefix)" IP="$(vm_ip)" ENV="single"
	@echo "✅ VM $(vm_prefix) created and metadata updated."

# Command: create talos-cluster
# Example: make create talos-cluster talos_prefix=dev ...
talos-cluster:
	@if [ -z "$(talos_prefix)" ]; then echo "Error: talos_prefix is required"; exit 1; fi
	@echo "🏗️ [ansible] Provisioning Talos nodes for cluster: $(talos_prefix)"
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini \
		playbooks/create-vm-server.yml \
		-e "talos_prefix=$(talos_prefix)" \
		-e "master_ip=$(master_ip)" \
		-e "worker_ip=$(worker_ip)" \
		-e "master_count=$(master_count)" \
		-e "worker_count=$(worker_count)" \
		-e "talos_iso_path=$(talos_iso_path)" \
		-e "talos_disk_dir=$(talos_disk_dir)" \
		-e "talos_network=$(talos_network)"
	
	@echo "🚀 [terraform] Applying Talos cluster configuration for $(talos_prefix)"
	@$(MAKE) -C $(TF_K8S_DIR) $(talos_prefix) apply
	
	@echo "📝 [metadata] Synchronizing instance metadata"
	@$(MAKE) metadata
	@echo "✅ Talos cluster $(talos_prefix) is ready."

# ── Metadata Management (using jq) ────────────────────────────────────────────

# Full sync: Parse sshconfig and generate vm.json
metadata:
	@echo "📝 Synchronizing $(VM_METADATA_FILE) from $(SSH_CONFIG)..."
	@grep -E "^Host |^	Hostname " $(SSH_CONFIG) | \
		sed 's/^\t//' | \
		awk '{if ($$1 == "Host") {host=$$2} else if ($$1 == "Hostname") {print host "," $$2}}' | \
		jq -R 'split(",") | {name: .[0], ip: .[1], env: (if .[0] | contains("-") then .[0] | split("-") | last else "infra" end)}' | \
		jq -s '.' > $(VM_METADATA_FILE)
	@echo "✅ Metadata sync complete."

# Atomic update: Upsert a single entry into vm.json
update-metadata:
	@jq '(.[] | select(.name == "$(NAME)")) |= (.ip = "$(IP)" | .env = "$(ENV)") | if any(.name == "$(NAME)") then . else . + [{"name": "$(NAME)", "ip": "$(IP)", "env": "$(ENV)"}] end' $(VM_METADATA_FILE) > $(VM_METADATA_FILE).tmp && mv $(VM_METADATA_FILE).tmp $(VM_METADATA_FILE)

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@echo "Available commands:"
	@echo "  make create vm vm_prefix=... vm_ip=... vm_cpu=... vm_mem=..."
	@echo "  make create talos-cluster talos_prefix=... master_ip=... worker_ip=..."
	@echo "  make metadata              # Regenerate vm.json from sshconfig"