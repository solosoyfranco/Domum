# **PiKVM with EZCOO KVM Switch 4x1**

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
