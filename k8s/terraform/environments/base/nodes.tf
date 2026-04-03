# Manage VMs for Talos cluster nodes using the talos-instance module.

# Since talos_masters and talos_workers are list of objects, 
# we can iterate over them to create instances.

# Let's define the nodes data as a local variable for clarity.
locals {
  # Prefix to be used for node names, similar to Ansible's talos_prefix
  node_prefix = "dev" # You might want to get this from a variable

  talos_masters = [
    {
      name      = "talos-vm-master-1-${local.node_prefix}"
      ip        = "192.168.122.20"
      memory    = 4096
      vcpus     = 4
      disk_size = 40
    }
  ]

  talos_workers = [
    {
      name      = "talos-vm-worker-1-${local.node_prefix}"
      ip        = "192.168.122.21"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "talos-vm-worker-2-${local.node_prefix}"
      ip        = "192.168.122.22"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "talos-vm-worker-3-${local.node_prefix}"
      ip        = "192.168.122.23"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "talos-vm-worker-4-${local.node_prefix}"
      ip        = "192.168.122.24"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    }
  ]
}

variable "talos_iso_path" {
  type    = string
  default = "/var/iso/metal-amd64.iso"
}

module "masters" {
  source = "git::ssh://git@github.com/venndev20999/homelabs-infrastructure-module.git//terraform/talos-instance"

  for_each = { for n in local.talos_masters : n.name => n }

  name       = each.value.name
  ip_address = each.value.ip
  memory     = each.value.memory
  vcpus      = each.value.vcpus
  disk_size  = each.value.disk_size
  iso_path   = var.talos_iso_path
}

module "workers" {
  source = "git::ssh://git@github.com/venndev20999/homelabs-infrastructure-module.git//terraform/talos-instance"

  for_each = { for n in local.talos_workers : n.name => n }

  name       = each.value.name
  ip_address = each.value.ip
  memory     = each.value.memory
  vcpus      = each.value.vcpus
  disk_size  = each.value.disk_size
  iso_path   = var.talos_iso_path
}
