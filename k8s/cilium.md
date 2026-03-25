patch.yml
```yaml
cluster:
  network:
    cni:
      name: none
  proxy:
    disabled: true

```

```bash
talosctl gen config talos-vm-cluster https://192.168.122.98:6443 \
  --output ./clusterconfig \
```


```bash
talosctl gen config talos-vm-cluster https://192.168.122.98:6443 \
  --output ./clusterconfig \
  --config-patch @patch.yml
```

```bash
talosctl apply-config --insecure \
  --nodes 192.168.122.98 \
  --file clusterconfig/controlplane.yaml
```


```bash
talosctl apply-config --insecure --endpoints 192.168.122.98   --talosconfig ./talosconfig \
  --nodes 192.168.122.96 \
  --file worker.yaml

talosctl apply-config --insecure --endpoints 192.168.122.98   --talosconfig ./talosconfig \
  --nodes 192.168.122.95 \
  --file worker.yaml

talosctl apply-config --insecure --endpoints 192.168.122.98   --talosconfig ./talosconfig \
  --nodes 192.168.122.83 \
  --file worker.yaml


talosctl apply-config --insecure --endpoints 192.168.122.98  --talosconfig ./talosconfig \
  --nodes 192.168.122.85 \
  --file worker.yaml


talosctl apply-config --insecure --endpoints 192.168.122.98  --talosconfig ./talosconfig \
  --nodes 192.168.122.97 \
  --file worker.yaml
```

export TALOSCONFIG=./clusterconfig/talosconfig
or
talosctl --talosconfig ./clusterconfig/talosconfig bootstrap \
  --nodes 192.168.122.98 \
  --endpoints 192.168.122.98


talosctl bootstrap --nodes 192.168.122.98 --endpoints 192.168.122.98


```sh
helm repo add cilium https://helm.cilium.io/
helm repo update

helm upgrade --install cilium cilium/cilium \
  --version 1.16.4 \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445 \
  --set nodePort.enabled=true \
  --set nodePort.bindProtection=false \
  --set l2announcements.enabled=true \
  --set kubeProxyReplacement=false

```




# metal lb
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

