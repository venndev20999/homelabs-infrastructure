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
TF_IMAGE     ?= hashicorp/terraform:light
ENVIRONMENTS  = dev staging prod
TF_ROOT      := $(shell pwd)   # must run from terraform/ directory

# ── Detect environment from first target ──────────────────────────────────────
# Allows: make dev apply  (env=dev, cmd=apply)
ENV  ?= dev
CMD  ?= help

# ── Docker base command ───────────────────────────────────────────────────────
DOCKER_RUN = docker run --rm -it \
	-v $(TF_ROOT):/workspace \
	-w /workspace/environments/$(ENV) \
	$(TF_IMAGE)

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
.PHONY: _init _plan _apply _destroy _output _validate _fmt _refresh _console

_init:
	@echo "🔧 [$(ENV)] terraform init"
	@$(DOCKER_RUN) init -upgrade

_plan:
	@echo "📋 [$(ENV)] terraform plan"
	@$(DOCKER_RUN) plan -var-file=terraform.tfvars -out=tfplan

_apply:
	@echo "🚀 [$(ENV)] terraform apply"
	@$(DOCKER_RUN) apply -var-file=terraform.tfvars -auto-approve

_apply-plan:
	@echo "🚀 [$(ENV)] terraform apply (from saved plan)"
	@$(DOCKER_RUN) apply tfplan

_destroy:
	@echo "💥 [$(ENV)] terraform destroy"
	@$(DOCKER_RUN) destroy -var-file=terraform.tfvars -auto-approve

_validate:
	@echo "✅ [$(ENV)] terraform validate"
	@$(DOCKER_RUN) validate

_fmt:
	@echo "🎨 Formatting all terraform files"
	@docker run --rm -v $(TF_ROOT):/workspace -w /workspace \
		$(TF_IMAGE) fmt -recursive

_refresh:
	@echo "🔄 [$(ENV)] terraform refresh"
	@$(DOCKER_RUN) refresh -var-file=terraform.tfvars

_console:
	@echo "💬 [$(ENV)] terraform console"
	@$(DOCKER_RUN) console -var-file=terraform.tfvars

# ── Output helpers ────────────────────────────────────────────────────────────
.PHONY: _output _kubeconfig _talosconfig

_output:
	@echo "📤 [$(ENV)] terraform outputs"
	@$(DOCKER_RUN) output

_kubeconfig:
	@echo "💾 [$(ENV)] Saving kubeconfig → environments/$(ENV)/output/kubeconfig"
	@mkdir -p $(TF_ROOT)/environments/$(ENV)/output
	@$(DOCKER_RUN) output -raw kubeconfig \
		> $(TF_ROOT)/environments/$(ENV)/output/kubeconfig
	@chmod 600 $(TF_ROOT)/environments/$(ENV)/output/kubeconfig
	@echo "✅ Run: export KUBECONFIG=$(TF_ROOT)/environments/$(ENV)/output/kubeconfig"

_talosconfig:
	@echo "💾 [$(ENV)] Saving talosconfig → environments/$(ENV)/output/talosconfig"
	@mkdir -p $(TF_ROOT)/environments/$(ENV)/output
	@$(DOCKER_RUN) output -raw talosconfig \
		> $(TF_ROOT)/environments/$(ENV)/output/talosconfig
	@chmod 600 $(TF_ROOT)/environments/$(ENV)/output/talosconfig
	@echo "✅ Run: export TALOSCONFIG=$(TF_ROOT)/environments/$(ENV)/output/talosconfig"

_state-list:
	@echo "📦 [$(ENV)] terraform state list"
	@$(DOCKER_RUN) state list

_state-show:
	@echo "📦 [$(ENV)] terraform state show $(RESOURCE)"
	@$(DOCKER_RUN) state show $(RESOURCE)

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
	@echo ""
	@echo "  Environments: dev | staging | prod"
	@echo "  Example: make dev init && make dev plan && make dev apply"
	@echo ""
