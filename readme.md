# Finance Stock Infrastructure

This directory contains the foundational infrastructure for the Finance Stock project. The infrastructure components are organized into dedicated folders for maintainability and separation of concerns.

## Architecture Overview

*   **Virtual Machines (VMs):** All virtual machines in this environment are deployed and managed on a **Cockpit VM Server**.
*   **Kubernetes (`k8s`):** The Kubernetes cluster uses **Talos Linux** as the operating system and is provisioned using **Terraform**.
*   **Service Deployments:** The following services are deployed and configured onto the Cockpit VMs using **Ansible Playbooks**:
    *   Elasticsearch
    *   PostgreSQL (`postgres`)
    *   Kafka Connect
    *   kSQL
    *   n8n

## Infrastructure Components

Each folder listed below maintains its own README file, which will contain detailed, step-by-step documentation for deployment and configuration:

*   **[`k8s/`](./k8s/readme.md):** Kubernetes configurations (Talos & Terraform)
*   **[`elasticsearch/`](./elasticsearch/readme.md):** Elasticsearch deployment details (Ansible playbook)
*   **[`postgres/`](./postgres/readme.md):** PostgreSQL database deployment details (Ansible playbook)
*   **[`kafka-connect/`](./kafka-connect/readme.md):** Kafka Connect deployment details (Ansible playbook)
*   **[`ksql/`](./ksql/readme.md):** kSQL deployment details (Ansible playbook)
*   **[`n8n/`](./n8n/readme.md):** n8n automation tool deployment details (Ansible playbook)

### Additional Components
*   `cloudflared/`: Cloudflared tunnel configurations
*   `kafka-server/`: Kafka server infrastructure details
*   `openclaw/`: Openclaw configurations

*Note: Component-specific details will be added to their respective README files over time.*
