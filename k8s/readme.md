# Kubernetes (k8s) Infrastructure

This directory contains the infrastructure code for deploying and managing the Kubernetes cluster for the Finance Stock project.

## Architecture

*   **Operating System**: [Talos Linux](https://www.talos.dev/), a modern OS built specifically for Kubernetes.
*   **Provisioning Tool**: [Terraform](https://www.terraform.io/) is used for infrastructure as code, deploying the required resources.
*   **Host Environment**: The virtual machines running Talos will be managed within the Cockpit VM Server environment.

## Usage & Deployment

*(Detailed deployment steps, Terraform state management, and configuration instructions will be added here.)*

## create new instance 

```bash
sudo virt-install \
  --name k-test-1 \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/k-test-1.qcow2,size=30,format=qcow2 \
  --cdrom /var/iso/metal-amd64.iso \
  --os-variant unknown \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=-1 \
  --graphics spice \
  --video qxl \
  --noautoconsole
```

## check dhcp
```sh
virsh net-dhcp-leases default
```
# edit dhcp

```sh
virsh net-edit default
```
## assign dhcp for instance
```sh
MAC=$(virsh domiflist docker-server | awk '/default/ {print $5}') && \
virsh net-update default add ip-dhcp-host \
  --xml "<host mac=\"$MAC\" name=\"docker-server\" ip=\"192.168.122.112\"/>" \
  --live --config && \
echo "✅ Reserved 192.168.122.112 for $MAC"
```
# reboot instance
```sh
virsh reboot docker-server
```


# set dhcp static ip for vms
## current running instance
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:74:44:1d' name='postgres'        ip='192.168.122.245'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:01:df:9c' name='elasticsearch01' ip='192.168.122.201' />" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:43:7c:67' name='docker-server'   ip='192.168.122.202' />" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:fe:64:3c' name='redis'           ip='192.168.122.203'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:27:ac:f7' name='cloudtools'      ip='192.168.122.204'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:fd:fa:a1' name='kafka-1'         ip='192.168.122.205'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:5c:83:1a' name='kafka-2'         ip='192.168.122.206'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:b3:94:b0' name='kafka-3'         ip='192.168.122.207'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:4f:53:71' name='haproxy'         ip='192.168.122.100'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:b8:26:6b' name='common'          ip='192.168.122.210'/>" --live --config

virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:61:69:8a' name='k-test-1'          ip='192.168.122.109'/>" --live --config


## unknown mac
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:5b:68:a4' ip='192.168.122.206'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:ed:9a:59' ip='192.168.122.142'/>" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:a0:92:7b' ip='192.168.122.84' />" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:35:08:8e' ip='192.168.122.48' />" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:8b:fc:b5' ip='192.168.122.49' />" --live --config
virsh net-update default add ip-dhcp-host --xml "<host mac='52:54:00:09:31:e0' ip='192.168.122.50' />" --live --config
