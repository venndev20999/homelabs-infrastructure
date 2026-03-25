# Provisioning Cilium CNI on Talos Linux

This guide explains how to install and configure the Cilium CNI on a Talos-based Kubernetes cluster, following the [official Sidero Labs documentation](https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#deploy-cilium-cni).

## Step 1: Prepare Talos Machine Configuration

By default, Talos installs Flannel as the CNI and enables `kube-proxy`. To use Cilium, you need to instruct Talos to skip the default CNI installation. If you plan to use Cilium's `kube-proxy` replacement (a common and recommended pattern for performance), you also need to disable `kube-proxy` in Talos.

Create a `patch.yaml` file depending on your choice:

**Option A: Disable Default CNI & kube-proxy (Recommended)**
Use this if you want Cilium to handle all routing and replace `kube-proxy`:
```yaml
cluster:
  network:
    cni:
      name: none
    proxy:
      disabled: true
```

**Option B: Disable Default CNI ONLY**
Use this if you want to keep Talos's default `kube-proxy`:
```yaml
cluster:
  network:
    cni:
      name: none
```

Apply the patch when generating your cluster configurations:
```bash
talosctl gen config my-cluster https://<cluster-endpoint>:6443 --config-patch @patch.yaml
```
*(Replace `my-cluster` and the cluster endpoint URL with your actual values).*

## Step 2: Deploy Cilium

Because Talos is an immutable OS, certain typical host capabilities (like automatic cgroup mounting) behave differently. Cilium installation requires explicit overrides for these restrictions.

### Method A: Using Helm

First, add and update the Helm repository:
```bash
helm repo add cilium https://helm.cilium.io/
helm repo update
```

Run the installation command that aligns with your `patch.yaml` choice in Step 1.

**If you used Option A (No kube-proxy):**
```bash
helm install cilium cilium/cilium \
  --version 1.18.0 \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445
```

**If you used Option B (With kube-proxy):**
```bash
helm install cilium cilium/cilium \
  --version 1.18.0 \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=false \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup
```
*(Optional: If you need the Gateway API, append `--set gatewayAPI.enabled=true --set gatewayAPI.enableAlpn=true --set gatewayAPI.enableAppProtocol=true` to your Helm command).*

### Method B: Using Pre-generated Manifests

If you have already generated a Helm template into a manifest file (such as the `cilium.yaml` provided in this directory), you can apply it directly to your cluster:

```bash
kubectl apply -f cilium.yaml
```

**Note:** If you generated your own `cilium.yaml`, ensure it includes the necessary `securityContext` and `cgroup` modifications listed in the Helm examples above so that the Cilium Agent can run successfully on Talos Linux.
