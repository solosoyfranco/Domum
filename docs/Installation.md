# **Installation Process: Control Plane (Hybrid HA)**

## **Overview**

Setup using **Proxmox** with Talos VM's and **Raspberry Pi's**, Kubernetes cluster with integration for Hashicorp Vault with External Secrets Operator (ESO), and GitOps.

---

## **Proxmox Installation**

### **VM Settings**

- **Default Settings**
  - **HDD:** 10 GB
  - **Cores:** 2
Follow these tutorial for the VM creation: <https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/>

## **Rpi4 Installation v1.9.3**
from (https://github.com/siderolabs/sbc-raspberrypi/issues/38) 
```bash
   curl -X POST --data-binary @rpi-config.yaml https://factory.talos.dev/schematics
   #{"id":"b21b89eb69a49191ba3eb72ff583bce6da242cfcdb1b9b108d0b10ad26bb13e8"}
   curl -o talos-rpi4.img.xz https://factory.talos.dev/image/b21b89eb69a49191ba3eb72ff583bce6da242cfcdb1b9b108d0b10ad26bb13e8/v1.9.3/metal-arm64.raw.xz
``` 

---

## Talos Installation

Running a “vanilla” Kubernetes distribution, where Talos handles the OS and Kubernetes lifecycle.

1. Building the ISO:
   - go to <https://factory.talos.dev>
   - Selections:
     - Cloud Server
     - Linux version:
     - 1.9.3
     - Nocloud
     - amd64 (SecureBoot off)
     - System Extensions
       - ~~siderolabs/cloudflared (2024.12.1)~~(was giving me errors)
       - ~~siderolabs/tailscale~~
       - ~~siderolabs/zfs~~
       - ~~siderolabs/nvidia-container-toolkit-lts~~
       - ~~siderolabs/lldpd~~
       - ~~siderolabs/thunderbolt~~
       - ~~siderolabs/nut-client~~
       - siderolabs/btrfs
       - siderolabs/fuse3
       - siderolabs/intel-ucode
       - siderolabs/iscsi-tools (required by longhorn)
       - siderolabs/util-linux-tools (required by longhorn)
       - siderolabs/qemu-guest-agent

2. Copy link for ISO and paste it on Proxmox for download and follow the instructions for the VM creations (<https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/>)
3. Run the ControlPlane VM (set the IP address on my router)

### **From the Terminal**

export this IP as a bash variable

```bash
export CONTROL_PLANE_IP=10.0.0.91
```

1. **Generate Talos Configuration:**

   ```bash
      talosctl gen config Domum-ControlPlane https://$CONTROL_PLANE_IP:6443 -o Secrets/Talos
      #run this command to check if the disk is sda id
      talosctl get disks --insecure --nodes $CONTROL_PLANE_IP
      #example
      ##runtime     Disk   sda      1         11 GB    false       virtio                          QEMU HARDDISK   
   ```

2. **Apply Configuration to the Control Plane VM:**

   ```bash
      talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file Secrets/Talos/controlplane.yaml

   ```

3. **Apply Configuration to the Worker VM:**

   ```bash
      export WORKER_IP=10.0.0.92
      talosctl apply-config --insecure --nodes $WORKER_IP --file Secrets/Talos/worker.yaml

   ```

4. **Using the Cluster:**

   ```bash
      export TALOSCONFIG="Secrets/Talos/talosconfig"
      talosctl config endpoint $CONTROL_PLANE_IP
      talosctl config node $CONTROL_PLANE_IP

      #get the dashboard
      talosctl dashboard --talosconfig Secrets/Talos/talosconfig
      #open multiple nodes dashboard
      talosctl dashboard --talosconfig Secrets/Talos/talosconfig --nodes 10.0.0.91,10.0.0.92

   ```

5. **Bootstrap Etcd:**

   ```bash
      talosctl bootstrap
   ```

6. **Retrieve the kubeconfig**

```bash
   talosctl kubeconfig .

```

## **Additional/Useful commands**

```bash

   #upgrade from factory.talos.dev (https://www.talos.dev/v1.9/talos-guides/upgrading-talos/)
   talosctl upgrade --image=factory.talos.dev/installer/b7615bc5ed2f5774cc5b1209043d13de7dc8d6146bbcd5ffbcacc29c80ea39f2:v1.9.3 -n 10.0.0.91 --force

   #system extensions
   talosctl get extensions -n 10.0.0.92

   # Get logs
   talosctl dmesg

   
   # Check nodes
   kubectl get nodes

   # Check services
   talosctl -n 10.0.0.90 services

   # Check contexts
   talosctl config contexts

   # Set a context
   talosctl config context Domum-ControlPlane

   ```

**Add an alias for easier use:**
   Add this to your `~/.zshrc` file:

   ```bash
   alias gitdomum='cd "CloudDocs/Git/Domum"'
   export KUBECONFIG="Secrets/Talos/kubeconfig"
   source ~/.zshrc
   ```

---

## **Managing Secrets**

### **Step 1: Add a `.gitignore` File**

   Create or edit the `.gitignore` file:
    ```bash
    nano .gitignore
    ```

   Add the following lines:
    ```plaintext
    # Ignore Talos configuration files
    Secrets/
    Secrets/ControlPlane-configs/controlplane.yaml
    Secrets/ControlPlane-configs/worker.yaml
    Secrets/ControlPlane-configs/talosconfig
    ```

### **Step 2: Prevent Accidental Upload of Existing Files**

   Untrack sensitive files:
    ```bash
    git rm --cached Secrets/ControlPane-configs/controlplane.yaml
    ```

### **Step 3: Export Talos Environment Variable**

   ```bash
      export TALOSCONFIG="Secrets/ControlPlane-configs/talosconfig"
   ```

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
