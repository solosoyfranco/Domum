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








## Optional: PiKVM with EZCOO KVM Switch 4x1
Install and Configure PiKVM
	1.	Flash PiKVM on an RPi4:
	- Download and flash the card.
	- Connect via SSH and configure:
```bash
# Default credentials: root:root
rw    # Switch to write mode
pacman -Syu  # Update the system
```
## Install Tailscale on PiKVM:
```bash
rw
pacman -Syu tailscale-pikvm
reboot now
# After reboot
pacman -Syu tailscale-pikvm
tailscale up
systemctl enable --now tailscale
```
- Authenticate using the provided URL.

## Improve Mouse Latency:
```bash
nano /boot/cmdline.txt
#Add the Following:
##usbhid.mousepoll=0
```
Save and exit.




## GPIO and HID Configuration for PiKVM
Edit /etc/kvmd/override.yaml:
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

## Fix PiKVM Permissions for Reboot and Service Restart

```bash
sudo nano /etc/sudoers
```
**Add These Lines:**
```yaml
kvmd ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart kvmd
kvmd ALL=(ALL) NOPASSWD: /usr/bin/reboot
```
## Verify the Syntax:
```bash
sudo visudo -c
#If correct, it will display:
##/etc/sudoers: parsed OK
```


---

## Environment Variable for Talos
Export the TALOS environment variable for ease of use: