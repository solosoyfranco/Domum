# **Talos Linux Kubernetes Cluster Deployment Guide**

## **Overview**

This guide walks through setting up a **Talos Linux Kubernetes Cluster** on **Proxmox** and **Raspberry Pi 4B**. It includes integration for **Hashicorp Vault**, **External Secrets Operator (ESO)**, and **GitOps**.

---

## **1. Proxmox Installation**

### **VM Settings**

- **Default Settings**:
  - **HDD:** 10 GB
  - **Cores:** 2

Follow the official guide for VM creation: [Talos on Proxmox](https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/).

---

## **2. Raspberry Pi 4B Installation (v1.9.3)**

### **Create Custom Talos Image for RPi4**

```bash
curl -X POST --data-binary @rpi-config.yaml https://factory.talos.dev/schematics
# Expected Output:
# {"id":"b21b89eb69a49191ba3eb72ff583bce6da242cfcdb1b9b108d0b10ad26bb13e8"}

curl -o talos-rpi4.img.xz https://factory.talos.dev/image/b21b89eb69a49191ba3eb72ff583bce6da242cfcdb1b9b108d0b10ad26bb13e8/v1.9.3/metal-arm64.raw.xz
```

---

## **3. Talos Installation (Vanilla Kubernetes Distribution)**

### **ISO Generation for Proxmox**

1. Visit [Talos Factory](https://factory.talos.dev) and generate an ISO with:
   - **Platform**: Cloud Server
   - **Version**: 1.9.3
   - **Architecture**: amd64 (SecureBoot OFF)
   - **System Extensions**:
     - siderolabs/btrfs
     - siderolabs/fuse3
     - siderolabs/intel-ucode
     - siderolabs/iscsi-tools (Required for Longhorn)
     - siderolabs/util-linux-tools (Required for Longhorn)
     - siderolabs/qemu-guest-agent

2. Download the ISO to **Proxmox**, create the VM, and boot the Control Plane.

---

## **4. Configure Talos Cluster**

### **Generate Configuration Files**

```bash
talosctl gen config talos-cluster https://10.0.0.90:6443 --output kubernetes/config/talos \
         --with-docs=false \
         --with-examples=false \
         --additional-sans 10.0.0.90,10.0.0.91,10.0.0.92
```

#### **Generated Files**
```
kubernetes/config/talos/
├── controlplane.yaml
├── worker.yaml
├── talosconfig
```

#### **Check Disk ID**

```bash
talosctl get disks --insecure --nodes 10.0.0.90
```

---

### **Create Patch Files for Disk Installation**

```bash
touch kubernetes/config/talos/patch-x86.yaml
# Content
machine:
  install:
    disk: /dev/sda


# For Raspberry Pi

touch kubernetes/config/talos/patch-rpi.yaml
# Content
machine:
  install:
    disk: /dev/mmcblk0
```

---

## **5. Apply Configuration to Nodes**

### **Control Plane Nodes**

```bash
talosctl apply-config -n 10.0.0.90 \
    -f kubernetes/config/talos/controlplane.yaml \
    --config-patch @kubernetes/config/talos/patch-rpi.yaml \
    --insecure
```

```bash
talosctl apply-config -n 10.0.0.91 \
    -f kubernetes/config/talos/controlplane.yaml \
    --config-patch @kubernetes/config/talos/patch-x86.yaml \
    --insecure
```

```bash
talosctl apply-config -n 10.0.0.92 \
    -f kubernetes/config/talos/controlplane.yaml \
    --config-patch @kubernetes/config/talos/patch-x86.yaml \
    --insecure
```

---

## **6. Set Talos Configuration Endpoint**

```bash
talosctl config endpoint 10.0.0.90
```

```bash
talosctl config endpoint 10.0.0.91
```

```bash
talosctl config endpoint 10.0.0.92
```

---

## **7. Bootstrap the Control Plane**

```bash
talosctl bootstrap -n 10.0.0.90
```

---

## **8. Retrieve Kubernetes Configuration**

```bash
talosctl kubeconfig -n 10.0.0.90
export KUBECONFIG=kubernetes/config/talos/kubeconfig
```

---

## **9. Verify Cluster Status**

```bash
kubectl get nodes
```

**Expected Output:**

```
NAME                    STATUS   ROLES           AGE     VERSION
controlplane-rpi4-90    Ready    control-plane   2m47s   v1.32.1
controlplane-91         Ready    control-plane   2m39s   v1.32.1
controlplane-92         Ready    control-plane   2m51s   v1.32.1
```

---

## **10. Configure Worker Nodes**

```bash
talosctl apply-config --insecure --nodes 10.0.0.93 --file kubernetes/config/talos/worker.yaml
```

```bash
talosctl apply-config --insecure --nodes 10.0.0.94 --file kubernetes/config/talos/worker.yaml
```

```bash
talosctl apply-config --insecure --nodes 10.0.0.95 --file kubernetes/config/talos/worker.yaml
```

---

## **11. Check Installed Extensions**

```bash
talosctl get extensions -n 10.0.0.90
```
```bash
talosctl get extensions -n 10.0.0.91
```
```bash
talosctl get extensions -n 10.0.0.92
```

---

## **12. Upgrade Talos**

```bash
talosctl upgrade --image=factory.talos.dev/installer/b7615bc5ed2f5774cc5b1209043d13de7dc8d6146bbcd5ffbcacc29c80ea39f2:v1.9.3 -n 10.0.0.91 --force
```

---

## **13. Monitoring and Debugging**

### **Check Logs**
```bash
talosctl dmesg
```

### **Check Node Status**
```bash
kubectl get nodes
```

### **Check Services on Nodes**
```bash
talosctl -n 10.0.0.90 services
```

### **List Talos Contexts**
```bash
talosctl config contexts
```

### **Set Context**
```bash
talosctl config context Domum-ControlPlane
```

### **Debugging Commands**
```bash
talosctl dmesg -n 10.0.0.90
talosctl logs -n 10.0.0.91
talosctl dashboard --talosconfig kubernetes/config/talos/talosconfig
```

---

**Setup Alias for Quick Access:**
```bash
echo 'alias gitdomum="cd CloudDocs/Git/Domum"' >> ~/.zshrc
source ~/.zshrc


---
control plane HA
kubectl apply -f kubernetes/app/kube-vip/rbac.yaml   
kubectl apply -f kubernetes/app/kube-vip/daemonset.yaml
diagnosis: 
kubectl describe ds kube-vip -n kube-system
kubectl get pods -n kube-system
kubectl logs daemonset/kube-vip -n kube-system

---
trying to patch the new VIP loadbalancer for controlplane
---
## **Flux Installation**

```bash
#generate the PAT from github
 flux bootstrap github \
  --owner=solosoyfranco \
  --repository=Domum \
  --branch=main \
  --path=cluster \
  --personal

#once is complete pull the files on git
git pull origin main


```

---

## **Longhorn Installation**

create the config

```bash
kubectl create -f cluster/infra/namespaces/longhorn.yaml
kubectl create -f cluster/helm-repos/longhorn.yaml
# apply it too
# now create the app
 kubectl apply -f cluster/apps/longhorn/longhorn.yaml
 #apply the service 
 kubectl apply -f cluster/apps/longhorn/longhorn-app.yaml  
 #access thry localhost8000
 kubectl port-forward -n longhorn-system svc/longhorn-ui 8000:8000
 #get the services and useful commands
 kubectl get svc -n longhorn-system
kubectl get deployment -n longhorn-system  
#Check Longhorn Logs for Errors
kubectl logs -n longhorn-system -l app=longhorn-manager
kubectl logs -n longhorn-system -l app=longhorn-ui
```

---

## **Kube-VIP Installation**

```bash
# manually added in case is needed
# helm repo add kube-vip https://kube-vip.github.io/helm-charts
# helm repo update 
helm search repo kube-vip/kube-vip --versions
kubectl apply -f cluster/apps/kube-vip/helmrepository.yaml  
kubectl apply -f cluster/apps/kube-vip/helmrelease.yaml   

# result: 
# > kubectl -n kube-system get pods -l app.kubernetes.io/name=kube-vip
# NAME             READY   STATUS    RESTARTS   AGE
# kube-vip-m5267   1/1     Running   0          5m47s
# kube-vip-n8qfn   1/1     Running   0          5m47s
# kube-vip-xrtdg   1/1     Running   0          5m47s
#quick test
kubectl apply -f cluster/apps/test/loadbalancer.yaml 
kubectl apply -f cluster/apps/test/deployment.yaml 
curl http://10.0.0.100
kubectl delete deployments nginx-test
```

## **Traefik + cert-manager Installation**

```bash
#cert manager check latest version https://github.com/cert-manager/cert-manager/releases
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml
#traefik
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.3/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

```

## **HashiCorp Vault Installation**

## **Deploy HashiCorp Vault via Helm**

For a simple, production-like setup, I'm using Vault’s Raft integrated storage.

### **1. Add the HashiCorp Helm repository**

   ```bash

    $ helm repo add hashicorp https://helm.releases.hashicorp.com
   #"hashicorp" has been added to your repositories
    helm repo update

   helm install vault hashicorp/vault
   ```

### **2. Create a namespace for Vault**

   ```bash

   ```

............

---

---
