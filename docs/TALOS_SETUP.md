# Talos Linux Kubernetes Cluster Setup

This document provides steps to configure a Talos Linux Kubernetes cluster with a Virtual IP (VIP) for High Availability.
Remember to check the disk name and patch the controlplane + the disk name.

ISO Generation and upgrades -> https://factory.talos.dev 
	Visit Talos Factory and generate an ISO with:
	
	- System Extensions (Varies depending on your case):
	- siderolabs/intel-ucode (only on my baremetal systems that have intel)
	- siderolabs/iscsi-tools (Required for Longhorn)
	- siderolabs/util-linux-tools (Required for Longhorn)
	- siderolabs/qemu-guest-agent (only for proxmox vms)

---

## **1. Generate Configuration Files**
```sh
talosctl gen config domum-cluster https://10.0.1.100:6443 \
  --output cluster/private/talos \
  --with-docs=false \
  --with-examples=false \
  --additional-sans 10.0.1.90,10.0.1.91,10.0.1.92 \
  --config-patch @cluster/core/01-talos/vip-config.yaml
```

This generates the following files:
- `cluster/private/talos/controlplane.yaml`
- `cluster/private/talos/worker.yaml`
- `cluster/private/talos/talosconfig`

### **VIP Configuration File (`vip-config.yaml`)**
```yaml
machine:
  network:
    interfaces:
      - deviceSelector:
          physical: true  # Ensures it selects a physical network interface
        dhcp: true
        vip:
          ip: 10.0.1.100

cluster:
  controlPlane:
    endpoint: https://10.0.1.100:6443
```

---

## **2. Apply Configuration to Control Plane Nodes**
```sh
talosctl apply-config -n 10.0.1.90 -f cluster/private/talos/controlplane.yaml --insecure
talosctl apply-config -n 10.0.1.91 -f cluster/private/talos/controlplane.yaml --insecure
talosctl apply-config -n 10.0.1.92 -f cluster/private/talos/controlplane.yaml --insecure
##example of disk patch
talosctl apply-config -n 10.0.1.92 -f cluster/private/talos/controlplane.yaml --config-patch @cluster/core/01-talos/rpi/disk-patch-rpi.yaml
```

### **3. Bootstrap the Cluster**
```sh
talosctl bootstrap -n 10.0.1.10
```

### **4. Set Endpoint for Talos**
```sh
talosctl config endpoint 10.0.1.100 10.0.1.10 10.0.1.11 10.0.1.12
talosctl config node 10.0.1.10 10.0.1.11 10.0.1.12
```

### **5. Verify Cluster Status**
```sh
kubectl get nodes
talosctl config contexts
talosctl dmesg -n 10.0.1.10

```

---

## **6. Patching & Applying Configurations**
🚨 **Important:** Do not use `--insecure` for patching or applying configs.

```sh
talosctl patch mc -p @cluster/core/01-talos/vip-patch-1.yaml -n 10.0.1.12
```

### **Check VIP Address**
```sh
talosctl get addresses --nodes 10.0.1.12  
```

---

## **7. Convert Control Plane to a Worker Node (For Homelab)**
```sh
kubectl describe node domum-x | grep Taints  
kubectl taint nodes domum-xr2 node-role.kubernetes.io/control-plane-
```
Then reboot the node:
```sh
talosctl reboot --nodes 10.0.1.11   
```

---

## **8. Reset & Start Fresh**
```sh
talosctl reset --nodes 10.0.1.10 --graceful=false
```

---

## **9. Retrieve Kubeconfig via VIP**
```sh
talosctl kubeconfig -n 10.0.1.100  # Using VIP
export KUBECONFIG=cluster/private/talos/kubeconfig
```

---

## **10. Verify High Availability (HA)**
```sh
kubectl get nodes -o wide
talosctl dashboard --nodes 10.0.1.100
```

---

## **11. Example Configuration Files**

### **Control Plane Configuration (`controlplane.yaml`)**
```yaml
version: v1alpha1
debug: false
persist: true
machine:
    type: controlplane
    token: ...
    ca:
        crt: ...
        key: ...
    certSANs:
        - 10.0.1.10
        - 10.0.1.11
        - 10.0.1.12
        - 10.0.1.100
    kubelet:
        image: ghcr.io/siderolabs/kubelet:v1.32.1
        defaultRuntimeSeccompProfileEnabled: true
        disableManifestsDirectory: true
    network:
        interfaces:
            - deviceSelector:
                physical: true
              dhcp: true
              vip:
                ip: 10.0.1.100
    install:
        disk: /dev/sda
        image: ghcr.io/siderolabs/installer:v1.9.3
        wipe: false
    features:
        rbac: true
        stableHostname: true
        apidCheckExtKeyUsage: true
        diskQuotaSupport: true
        kubePrism:
            enabled: true
            port: 7445
        hostDNS:
            enabled: true
            forwardKubeDNSToHost: true
    nodeLabels:
        node.kubernetes.io/exclude-from-external-load-balancers: ""
cluster:
    id: ...
    secret: ...
    controlPlane:
        endpoint: https://10.0.1.100:6443
    clusterName: domum-cluster
    network:
        dnsDomain: cluster.local
        podSubnets:
            - 10.244.0.0/16
        serviceSubnets:
            - 10.96.0.0/12
    token: ...
    secretboxEncryptionSecret: ...
    ca:
        crt: ...
        key: ...
    aggregatorCA:
        crt: ...
        key: ...
    serviceAccount:
        key: ....
    apiServer:
        image: registry.k8s.io/kube-apiserver:v1.32.1
        certSANs:
            - 10.0.1.100
            - 10.0.1.90
            - 10.0.1.91
            - 10.0.1.92
        disablePodSecurityPolicy: true
        admissionControl:
            - name: PodSecurity
              configuration:
                apiVersion: pod-security.admission.config.k8s.io/v1alpha1
                defaults:
                    audit: restricted
                    audit-version: latest
                    enforce: baseline
                    enforce-version: latest
                    warn: restricted
                    warn-version: latest
                exemptions:
                    namespaces:
                        - kube-system
                    runtimeClasses: []
                    usernames: []
                kind: PodSecurityConfiguration
        auditPolicy:
            apiVersion: audit.k8s.io/v1
            kind: Policy
            rules:
                - level: Metadata
    controllerManager:
        image: registry.k8s.io/kube-controller-manager:v1.32.1
    proxy:
        image: registry.k8s.io/kube-proxy:v1.32.1
    scheduler:
        image: registry.k8s.io/kube-scheduler:v1.32.1
    discovery:
        enabled: true
        registries:
            kubernetes:
                disabled: true
            service: {}
    etcd:
        ca:
            crt: 
            ...
            key:
            ...
```

### **Worker Node Configuration (`worker.yaml`)**
```yaml
version: v1alpha1
debug: false
persist: true
machine:
    type: worker
    token: ...
    ca:
        crt: ...
        key: ""
    certSANs:
        - 10.0.1.90
        - 10.0.1.91
        - 10.0.1.92
        - 10.0.1.100
    kubelet:
        image: ghcr.io/siderolabs/kubelet:v1.32.1
        defaultRuntimeSeccompProfileEnabled: true
        disableManifestsDirectory: true
    network:
        interfaces:
            - deviceSelector:
                physical: true
              dhcp: true
    install:
        disk: /dev/sda
        image: ghcr.io/siderolabs/installer:v1.9.4
        wipe: false
    features:
        rbac: true
        stableHostname: true
        apidCheckExtKeyUsage: true
        diskQuotaSupport: true
        kubePrism:
            enabled: true
            port: 7445
        hostDNS:
            enabled: true
            forwardKubeDNSToHost: true
cluster:
    id: ...
    secret: ...
    controlPlane:
        endpoint: https://10.0.1.100:6443
    clusterName: domum-cluster
    network:
        dnsDomain: cluster.local
        podSubnets:
            - 10.244.0.0/16
        serviceSubnets:
            - 10.96.0.0/12
    token: ...
    ca:
        crt: ...
        key: ""
    discovery:
        enabled: true
        registries:
            kubernetes:
                disabled: true
            service: {}
```

---

## **12. Watch and Test Services**
```sh
watch -n 2 curl --resolve demo.localdev.me:31253:10.0.1.10 http://demo.localdev.me:31253
```
## **13. Change name of Nodes**
```bash
talosctl patch mc --nodes 10.0.1.10 -p '{"machine":{"network":{"hostname":"domum-x"}}}'
#Restart nodes for changes to take effect:
talosctl reboot --nodes 10.0.1.10,10.0.1.11,10.0.1.12
#Cordon & Drain the Node (if needed)
kubectl cordon talos-7ks-bsd
kubectl drain talos-7ks-bsd --ignore-daemonsets --delete-emptydir-data
#Manually Remove the Old Node (Talos will re-register it)
kubectl delete node talos-7ks-bsd
``` 

---



## **Adding Metrics**
Documentation: https://www.talos.dev/v1.9/kubernetes-guides/configuration/deploy-metrics-server/

```bash
kubectl apply -f https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
#then
talosctl patch mc -p @cluster/core/01-talos/metrics-config.yaml -n 10.0.1.10,10.0.1.11,10.0.1.12,10.0.1.13,10.0.1.14
#test
kubectl top nodes
``` 