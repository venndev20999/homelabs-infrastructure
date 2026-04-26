# Manage VMs for Talos cluster nodes using the talos-instance module.

# Since talos_masters and talos_workers are list of objects, 
# we can iterate over them to create instances.

# Let's define the nodes data as a local variable for clarity.
locals {
  # Prefix to be used for node names, similar to Ansible's talos_prefix
  node_prefix = "test"

  talos_masters = [
    {
      name      = "tl-master-${local.node_prefix}"
      ip        = "192.168.122.120"
      memory    = 4096
      vcpus     = 4
      disk_size = 40
    }
  ]

  talos_workers = [
    {
      name      = "tl-worker-1-${local.node_prefix}"
      ip        = "192.168.122.121"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    },
    {
      name      = "tl-worker-2-${local.node_prefix}"
      ip        = "192.168.122.122"
      memory    = 2048
      vcpus     = 2
      disk_size = 30
    }
  ]
}
