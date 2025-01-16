# Installation Process: Control Plane (Hybrid HA)
**Setup with Proxmox as the primary control plane and Raspberry Pi 5 as the secondary.**

---

## Proxmox Installation

### VM Settings
- Use default settings.
- **HDD:** 10 GB  
- **Cores:** 2  

---

## Talos Configuration

### From the Terminal:
1. **Generate Talos Configuration:**
   ```bash
   talosctl gen config Domum-ControlPlane https://10.0.0.90:6443 -o Secrets/ControlPlane-configs
   ```
2. **Apply Configuration to the Control Plane VM:**
```bash
talosctl apply-config -e 10.0.0.90 -n 10.0.0.90 --insecure -f ControlPlane-configs/controlplane.yaml
```
3. **Apply Configuration to the Worker VM:**
   ```bash
   talosctl apply-config -e 10.0.0.92 -n 10.0.0.92 --insecure -f ControlPlane-configs/worker.yaml
   ```

---
## Managing Secrets
1. **Add a .gitignore File:**
open or create a .gitignore file:
```bash
nano .gitignore
```

2. **Add the Following Lines:**
```
   # Ignore Talos configuration files
Secrets/
Secrets/ControlPane-configs/controlplane.yaml
Secrets/ControlPane-configs/worker.yaml
Secrets/ControlPane-configs/talosconfig
```
3. **Optional: Prevent Accidental Upload of Existing Files**
Untrack sensitive files from Git:
```bash
git rm --cached Secrets/ControlPane-configs/controlplane.yaml
```
---
## Environment Variable for Talos
Export the TALOS environment variable for ease of use: