# **Installation Process: Control Plane (Hybrid HA)**
### **Overview**
Setup using **Proxmox** with Talos VM's and **Raspberry Pi's**, Kubernetes cluster with integration for Hashicorp Vault with External Secrets Operator (ESO), and GitOps.


---

## **Proxmox Installation**

### **VM Settings**
- **Default Settings**
  - **HDD:** 10 GB
  - **Cores:** 2
Follow these tutorial for the VM creation: https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/
---

## Talos Installation
Running a “vanilla” Kubernetes distribution, where Talos handles the OS and Kubernetes lifecycle.
1. Building the ISO: 
   - go to https://factory.talos.dev
   - Selections:
     - Cloud Server
     - Linux version:
     - 1.9.3
     - Nocloud
     - amd64 (SecureBoot off)
     - System Extensions
       - siderolabs/cloudflared (2024.12.1)
       - siderolabs/qemu-guest-agent (9.2.0)
       - siderolabs/tailscale
       - siderolabs/btrfs
       - siderolabs/zfs
       - siderolabs/nvidia-container-toolkit-lts 
       - siderolabs/fuse3
       - siderolabs/util-linux-tools
       - siderolabs/intel-ucode or siderolabs/amd-ucode
       - siderolabs/lldpd
       - siderolabs/thunderbolt
       - siderolabs/nut-client

2. Copy link for ISO and paste it on Proxmox for download and follow the instructions for the VM creations (https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/)
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

7. **Additional/Useful commands**
```bash

   #upgrade from factory.talos.dev (https://www.talos.dev/v1.9/talos-guides/upgrading-talos/)
   talosctl updagrade -i factory.talos.dev/installer/ec5bdeb6f98993950c828f5545b3fbd205be7ad8dceee696cce6b2b9217269de:v1.9.3 --force
   talosctl updagrade -n $WORKER_IP -i  factory.talos.dev/installer/ec5bdeb6f98993950c828f5545b3fbd205be7ad8dceee696cce6b2b9217269de:v1.9.3 --force

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

8. **Add an alias for easier use:**
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

## **HashiCorp Vault Installation**
## **Deploy HashiCorp Vault via Helm**
For a simple, production-like setup, I'm using Vault’s Raft integrated storage.

### **1. Add the HashiCorp Helm repository**
    ```bash
    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm repo update    
    ```

### **2. Create a namespace for Vault**

   ```bash
   kubectl create namespace vault
   ``` 
............

---


--- 