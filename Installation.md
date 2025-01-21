# **Installation Process: Control Plane (Hybrid HA)**
### **Overview**
Setup using **Proxmox** as the primary control plane and **Raspberry Pi 5** as the secondary, with integration for Hashicorp Vault (LXC Debian), Kubernetes, and GitOps.


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

```
## **HashiCorp Vault Installation**

### **Step 1: Install Vault in an LXC Container**
1. Create an LXC container in **Proxmox GUI** using the latest Debian image.
2. Inside the LXC container:
   ```bash
   apt update
   apt upgrade -y
   apt install sudo gpg lsb-release -y

   # Install HashiCorp keyring
   wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null

   # Verify the keyring fingerprint
   gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

   # Add HashiCorp repo
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

   apt update
   apt install vault -y
   ```

3. Verify permissions for Vault storage:
   ```bash
   mkdir -p /vault/data
   chown -R vault:vault /vault/data
   ```

---

### **Step 2: Generate TLS Certificates**
1. Install OpenSSL:
   ```bash
   apt install openssl -y
   ```

2. Generate a private key:
   ```bash
   openssl genrsa -out vault-key.pem 2048
   ```

3. Generate a CSR:
   ```bash
   openssl req -new -key vault-key.pem -out vault-csr.pem        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=10.0.0.8"
   ```

4. Generate a self-signed certificate:
   ```bash
   openssl x509 -req -in vault-csr.pem -signkey vault-key.pem -out vault-cert.pem -days 365
   ```

---

### **Step 3: Configure Vault**
Edit `/etc/vault.d/vault.hcl`:
```hcl
# Storage backend
storage "file" {
  path = "/vault/data"
}

# Listener configuration (HTTPS)
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault.d/vault-cert.pem"
  tls_key_file  = "/etc/vault.d/vault-key.pem"
}

# API address
api_addr = "https://10.0.0.8:8200"

# UI
ui = true
```

---

### **Step 4: Start Vault**
1. Start Vault with the configuration file:
   ```bash
   vault server -config=/etc/vault.d/vault.hcl
   ```

2. Verify Vault status:
   ```bash
   export VAULT_ADDR='https://10.0.0.8:8200'
   vault status
   ```

3. Check logs for errors:
   ```bash
   journalctl -u vault
   ```

---

### **Vault as a service**

```bash
cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target

EOF
```
### **Check Status**
```bash
systemctl status -l vault
* vault.service - "HashiCorp Vault - A tool for managing secrets"
     Loaded: loaded (/lib/systemd/system/vault.service; disabled; vendor preset: enabled)
     Active: activating (start) since Thu 2023-12-14 03:08:08 UTC; 1min 4s ago
       Docs: https://developer.hashicorp.com/vault/docs
   Main PID: 544 (vault)
      Tasks: 6 (limit: 38261)
     Memory: 22.4M
        CPU: 108ms
     CGroup: /system.slice/vault.service
             `-544 /usr/bin/vault server -config=/etc/vault.d/vault.hcl
```
---
## **Optional: PiKVM with EZCOO KVM Switch 4x1**

### **Step 1: Flash PiKVM**
1. Download and flash the card from the official site.
2. Connect via SSH with default credentials:
   ```bash
   # Default credentials: root:root
   rw    # Switch to write mode
   pacman -Syu  # Update the system
   ```

### **Step 2: Install Tailscale**
```bash
rw
pacman -Syu tailscale-pikvm
reboot now
# After reboot
tailscale up
systemctl enable --now tailscale
```

### **Step 3: Configure GPIO and HID**
Edit `/etc/kvmd/override.yaml` to configure GPIO for the EZCOO KVM switch.
    ```yaml
    kvmd:
        hid:
            mouse:
                absolute: false
        gpio:
            drivers:
                ez:
                    type: ezcoo
                    protocol: 2
                    device: /dev/ttyUSB0
                reboot:
                    type: cmd
                    cmd: [/usr/bin/sudo, reboot]
                restart_service:
                    type: cmd
                    cmd: [/usr/bin/sudo, systemctl, restart, kvmd]
            scheme:
                ch0_led:
                    driver: ez
                    pin: 0
                    mode: input
                ch1_led:
                    driver: ez
                    pin: 1
                    mode: input
                ch2_led:
                    driver: ez
                    pin: 2
                    mode: input
                ch3_led:
                    driver: ez
                    pin: 3
                    mode: input
                pikvm_led:
                    pin: 0
                    mode: input
                ch0_button:
                    driver: ez
                    pin: 0
                    mode: output
                    switch: false
                ch1_button:
                    driver: ez
                    pin: 1
                    mode: output
                    switch: false
                ch2_button:
                    driver: ez
                    pin: 2
                    mode: output
                    switch: false
                ch3_button:
                    driver: ez
                    pin: 3
                    mode: output
                    switch: false
                reboot_button:
                    driver: reboot
                    pin: 0
                    mode: output
                    switch: false
                restart_service_button:
                    driver: restart_service
                    pin: 0
                    mode: output
                    switch: false
            view:
                table:
                    - ["#Domum-X", ch0_led, ch0_button]
                    - ["#Domum-XI", ch1_led, ch1_button]
                    - ["#Domum-XII", ch2_led, ch2_button]
                    - ["#RPI5-CPlane", ch3_led, ch3_button]
                    - ["#PiKVM", "pikvm_led|green", "restart_service_button|confirm|Service", "reboot_button|confirm|Reboot"]
    ```
---

### **Step 4: Fix Permissions**
1. Add sudo permissions for PiKVM:
   ```bash
   sudo nano /etc/sudoers
   ```

2. Add:
   ```plaintext
   kvmd ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart kvmd
   kvmd ALL=(ALL) NOPASSWD: /usr/bin/reboot
   ```

3. Verify with:
   ```bash
   sudo visudo -c
   ```


### **Step 5: Improve Mouse Latency (Optional):**
```bash
nano /boot/cmdline.txt
#Add the Following:
##usbhid.mousepoll=0
```
Save and exit.


---

## **Kubernetes Dashboard Installation**

1. Apply the Kubernetes dashboard YAML:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
   ```

2. Access the dashboard:
   ```bash
   kubectl proxy
   ```

3. Open in your browser:
   ```
   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
   ```

---

