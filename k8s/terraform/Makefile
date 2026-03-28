# ─────────────────────────────────────────────────────────────────────────────
# Terraform Makefile — finance-stock k8s cluster
# Usage:
#   make <env> <command>
#   make dev init
#   make dev plan
#   make dev apply
#   make dev destroy
#   make dev output
#   make dev kubeconfig
#   make dev console
#
# Environments: dev | staging | prod
# ─────────────────────────────────────────────────────────────────────────────

# ── Config ────────────────────────────────────────────────────────────────────
ENVIRONMENTS  = dev staging prod
TF_ROOT      := $(shell pwd)   # must run from terraform/ directory

# ── Detect environment from first target ──────────────────────────────────────
# Allows: make dev apply  (env=dev, cmd=apply)
ENV  ?= dev
CMD  ?= help

# ── Terraform base command ────────────────────────────────────────────────────
TF = terraform -chdir=environments/$(ENV)

# ── Environment targets (make dev / make staging / make prod) ─────────────────
.PHONY: $(ENVIRONMENTS)
$(ENVIRONMENTS):
	@$(MAKE) _run ENV=$@ CMD=$(filter-out $@,$(MAKECMDGOALS))

# Swallow extra args so make doesn't complain
%:
	@:

# ── Core runner ───────────────────────────────────────────────────────────────
.PHONY: _run
_run:
	@$(MAKE) _$(CMD) ENV=$(ENV)

# ── Terraform commands ────────────────────────────────────────────────────────
.PHONY: _init _plan _apply _apply-plan _destroy _validate _fmt _refresh _console _purge _purge-apply

_init:
	@echo "🔧 [$(ENV)] terraform init"
	@$(TF) init -upgrade

_plan:
	@echo "📋 [$(ENV)] terraform plan"
	@$(TF) plan -var-file=terraform.tfvars -out=tfplan

_apply:
	@echo "🚀 [$(ENV)] terraform apply"
	@$(TF) apply -var-file=terraform.tfvars -auto-approve

_apply-plan:
	@echo "🚀 [$(ENV)] terraform apply (from saved plan)"
	@$(TF) apply tfplan

_destroy:
	@echo "💥 [$(ENV)] terraform destroy"
	@$(TF) destroy -var-file=terraform.tfvars -auto-approve

_validate:
	@echo "✅ [$(ENV)] terraform validate"
	@$(TF) validate

_fmt:
	@echo "🎨 Formatting all terraform files"
	@terraform fmt -recursive

_refresh:
	@echo "🔄 [$(ENV)] terraform refresh"
	@$(TF) refresh -var-file=terraform.tfvars

_console:
	@echo "💬 [$(ENV)] terraform console"
	@$(TF) console -var-file=terraform.tfvars

_purge:
	@echo "🔥 [$(ENV)] Purging terraform state and local files"
	@rm -rf environments/$(ENV)/.terraform
	@rm -f environments/$(ENV)/terraform.tfstate
	@rm -f environments/$(ENV)/terraform.tfstate.backup
	@rm -f environments/$(ENV)/.terraform.lock.hcl
	@rm -f environments/$(ENV)/tfplan
	@echo "✅ State purged"

_purge-apply: _purge _init _apply

# ── Output helpers ────────────────────────────────────────────────────────────
.PHONY: _output _kubeconfig _talosconfig

_output:
	@echo "📤 [$(ENV)] terraform outputs"
	@$(TF) output

_kubeconfig:
	@echo "💾 [$(ENV)] Saving kubeconfig → environments/$(ENV)/output/kubeconfig"
	@mkdir -p $(TF_ROOT)/environments/$(ENV)/output
	@$(TF) output -raw kubeconfig \
		> $(TF_ROOT)/environments/$(ENV)/output/kubeconfig
	@chmod 600 $(TF_ROOT)/environments/$(ENV)/output/kubeconfig
	@echo "✅ Run: export KUBECONFIG=$(TF_ROOT)/environments/$(ENV)/output/kubeconfig"

_talosconfig:
	@echo "💾 [$(ENV)] Saving talosconfig → environments/$(ENV)/output/talosconfig"
	@mkdir -p $(TF_ROOT)/environments/$(ENV)/output
	@$(TF) output -raw talosconfig \
		> $(TF_ROOT)/environments/$(ENV)/output/talosconfig
	@chmod 600 $(TF_ROOT)/environments/$(ENV)/output/talosconfig
	@echo "✅ Run: export TALOSCONFIG=$(TF_ROOT)/environments/$(ENV)/output/talosconfig"

_state-list:
	@echo "📦 [$(ENV)] terraform state list"
	@$(TF) state list

_state-show:
	@echo "📦 [$(ENV)] terraform state show $(RESOURCE)"
	@$(TF) state show $(RESOURCE)

# ── Utility ───────────────────────────────────────────────────────────────────
.PHONY: help list-envs

help:
	@echo ""
	@echo "  Talos K8s Terraform — Available commands"
	@echo "  ─────────────────────────────────────────────────"
	@echo "  make <env> init           — Initialize providers & modules"
	@echo "  make <env> plan           — Preview changes"
	@echo "  make <env> apply          — Deploy cluster"
	@echo "  make <env> apply-plan     — Apply saved plan from 'plan'"
	@echo "  make <env> destroy        — Tear down cluster"
	@echo "  make <env> validate       — Validate HCL syntax"
	@echo "  make <env> fmt            — Format all .tf files"
	@echo "  make <env> output         — Show all outputs"
	@echo "  make <env> kubeconfig     — Save kubeconfig to output/"
	@echo "  make <env> talosconfig    — Save talosconfig to output/"
	@echo "  make <env> state-list     — List Terraform state resources"
	@echo "  make <env> refresh        — Refresh state from real infra"
	@echo "  make <env> console        — Interactive Terraform console"
	@echo "  make <env> purge          — 🔥 Remove all local state and lock files"
	@echo "  make <env> purge-apply    — 🔥 Radical reset: purge, init, then apply"
	@echo ""
	@echo "  Environments: dev | staging | prod"
	@echo "  Example: make dev init && make dev plan && make dev apply"
	@echo ""
