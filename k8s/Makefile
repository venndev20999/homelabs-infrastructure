# Define directories
STG_DIR = terraform/environments/stg
ADD_ONS_DIR = terraform/environments/stg-add-ons

# Ensure SOPS uses the correct age key file path
export SOPS_AGE_KEY_FILE ?= $(HOME)/.config/sops/age/keys.txt

.PHONY: all stg-plan stg-apply addons-plan addons-apply encrypt-secrets decrypt-secrets

# Default target
all: stg-plan addons-plan

# Helper targets to encrypt/decrypt local secrets file using sops
encrypt-secrets:
	@if [ -f secrets.dec.yaml ]; then \
		sops -e secrets.dec.yaml > secrets.enc.yaml && \
		echo "secrets.dec.yaml successfully encrypted to secrets.enc.yaml."; \
	else \
		echo "Error: secrets.dec.yaml not found! Create it first with your variables."; \
	fi

decrypt-secrets:
	@if [ -f secrets.enc.yaml ]; then \
		sops -d secrets.enc.yaml > secrets.dec.yaml && \
		echo "secrets.enc.yaml successfully decrypted to secrets.dec.yaml."; \
	else \
		echo "Error: secrets.enc.yaml not found!"; \
	fi

# Staging Environment Targets
stg-plan: decrypt-secrets
	@cd $(STG_DIR) && \
	if [ -f ../../../secrets.dec.yaml ]; then \
		eval $$(grep -v '^#' ../../../secrets.dec.yaml | grep -v '^$$' | sed -e 's/: /=/' -e 's/^/export /') && \
		terraform plan; \
	else \
		terraform plan; \
	fi

stg-apply: decrypt-secrets
	@cd $(STG_DIR) && \
	if [ -f ../../../secrets.dec.yaml ]; then \
		eval $$(grep -v '^#' ../../../secrets.dec.yaml | grep -v '^$$' | sed -e 's/: /=/' -e 's/^/export /') && \
		terraform apply; \
	else \
		terraform apply; \
	fi

# Add-Ons Environment Targets
addons-plan: decrypt-secrets
	@cd $(ADD_ONS_DIR) && \
	if [ -f ../../../secrets.dec.yaml ]; then \
		eval $$(grep -v '^#' ../../../secrets.dec.yaml | grep -v '^$$' | sed -e 's/: /=/' -e 's/^/export /') && \
		terraform plan; \
	else \
		terraform plan; \
	fi

addons-apply: decrypt-secrets
	@cd $(ADD_ONS_DIR) && \
	if [ -f ../../../secrets.dec.yaml ]; then \
		eval $$(grep -v '^#' ../../../secrets.dec.yaml | grep -v '^$$' | sed -e 's/: /=/' -e 's/^/export /') && \
		terraform apply; \
	else \
		terraform apply; \
	fi

