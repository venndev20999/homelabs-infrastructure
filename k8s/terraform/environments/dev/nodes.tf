# Manage VMs for Talos cluster nodes using the talos-instance module.

# Since talos_masters and talos_workers are list of objects, 
# we can iterate over them to create instances.

# Let's define the nodes data as a local variable for clarity.
locals {
  # Prefix to be used for node names, similar to Ansible's talos_prefix
  node_prefix = "dev"

  talos_masters = [
    {
      name      = "tl-master-${local.node_prefix}"
      ip        = "192.168.122.20"
      memory    = 4096
      vcpus     = 4
      disk_size = 40
    }
  ]

  talos_workers = [
    {
      name      = "tl-worker-1-${local.node_prefix}"
      ip        = "192.168.122.21"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "tl-worker-2-${local.node_prefix}"
      ip        = "192.168.122.22"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "tl-worker-3-${local.node_prefix}"
      ip        = "192.168.122.23"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "tl-worker-4-${local.node_prefix}"
      ip        = "192.168.122.24"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "tl-worker-5-${local.node_prefix}"
      ip        = "192.168.122.25"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    }
  ]
}
