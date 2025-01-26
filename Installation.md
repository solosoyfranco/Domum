# **Installation Process: Control Plane (Hybrid HA)**
### **Overview**
Setup using **Proxmox** with Talos VM's and **Raspberry Pi's**, Kubernetes cluster with integration for Hashicorp Vault with External Secrets Operator (ESO), and GitOps.


---

## **Proxmox Installation**

### **VM Settings**
- **Default Settings**
  - **HDD:** 10 GB
  - **Cores:** 2

---

## Talos Configuration

### **From the Terminal**
1. **Generate Talos Configuration:**
   
   ```bash
   talosctl gen config Domum-ControlPlane https://10.0.0.90:6443 -o Secrets/ControlPlane-configs
   ```

2. **Apply Configuration to the Control Plane VM:**
   
   ```bash
   talosctl apply-config -e 10.0.0.90 -n 10.0.0.90 --insecure -f Secrets/ControlPlane-configs/controlplane.yaml
   talosctl apply-config -n 10.0.0.90 -f Secrets/ControlPlane-configs/controlplane.yaml
   ```

3. **Apply Configuration to the Worker VM:**
   
   ```bash
   talosctl apply-config -e 10.0.0.92 -n 10.0.0.92 --insecure -f Secrets/ControlPlane-configs/worker.yaml
   ```

4. **Additional Talos Commands:**
   
   ```bash
   talosctl config endpoint 10.0.0.90
   talosctl config nodes 10.0.0.90

   # Get logs
   talosctl dmesg

   # Generate kubeconfig
   talosctl kubeconfig . -f

   # Export kubeconfig environment variable
   export KUBECONFIG=kubeconfig

   # Check nodes
   kubectl get nodes

   # Check services
   talosctl -n 10.0.0.90 services

   # Check contexts
   talosctl config contexts

   # Set a context
   talosctl config context Domum-ControlPlane

   # Merge kubeconfig
   talosctl config merge Secrets/ControlPlane-configs/talosconfig

   # Re-check Kubernetes after fixing Talos
   talosctl -n 10.0.0.90 kubeconfig Secrets/ControlPlane-configs/controlplane.yaml
   export KUBECONFIG=Secrets/ControlPlane-configs/controlplane.yaml
   kubectl get nodes
   ```

5. **Add an alias for easier use:**
   Add this to your `~/.zshrc` file:
   ```bash
   alias gitdomum='cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Git/Domum"'
   export KUBECONFIG="Secrets/ControlPlane-configs/controlplane.yaml"
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

### **2. Create a HelmRelease (Flux) for Vault**

File in:Domum/clusters/vault/vault-helmrelease.yaml
............

---


--- 