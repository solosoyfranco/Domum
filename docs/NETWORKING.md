# Networking & VLAN Architecture

This document describes the network layout, VLAN segments, and IP schema for the Domum homelab environment.

---

## 1. Overview

- **Router:** UniFi Router
- **Core Switch(es):** UniFi/Cisco managed switches
- **Wireless APs:** UniFi APs
- **Gateway/Subnet:** `10.0.0.0/24` (primary LAN)

---

## 2. VLAN & Subnet Structure

| VLAN | Subnet          | Purpose                      | Notes                                        |
|-----:|:----------------|:-----------------------------|:---------------------------------------------|
|  1   | `10.0.0.0/24`   | **Main LAN**                 | Trusted devices, servers, clusters, network  |
|  10  | `10.10.10.1/24`  | **Users**                    | Trusted devices, e.g., personal workstations |
|  20  | `10.10.20.1/24` | **Gaming**                   | LAN for VR, and Gaming devices               |
|  30  | `10.10.30.1/24` | **Guest WiFi**               | Separate wireless network                    |
|  40  | `10.10.40.1/24` | **IoT**                      |  Isolated from main LAN                      |
|  50  | `10.10.50.1/24` | **Cameras**                  |  Security Cameras                            |
| 888  | `10.10.88.1/24` | **Exposed**                  | Future public services                       |

*(Adjust VLAN IDs and subnets per your environment.)*

### VLAN Gateway Interfaces

- **Router Interface VLAN 10:** `10.10.10.1`
- **Router Interface VLAN 20:** `10.10.20.1`
- **Router Interface VLAN 30:** `10.10.30.1`
- **Router Interface VLAN 40:** `10.10.40.1`
- **Router Interface VLAN 40:** `10.10.50.1`
- **Router Interface VLAN 888:** `10.10.88.1`

---

## 3. DNS & DHCP

- **DNS** is handled by UniFi (or Unbound) on the homelab VLAN.  
- **DHCP** for all VLANs is managed on UniFi with static reservations for critical devices (e.g., Cluster nodes, Proxmox servers, Raspberry Pis, etc.).

---

## 4. Kubernetes Networking

- **HA Controlplane**: Managed by VIP in `10.0.0.100`.
- **Pod Network**: Handled via CNI (e.g., Calico or Cilium).  
- **LoadBalancer**: Managed by Traefik in `10.0.0.101`.

---

## 5. Security & Firewall Rules

1. **Inter-VLAN Filtering**:  
   - Deny by default; allow only necessary ports/protocols between VLANs (e.g., SSH, HTTPS).  
2. **Remote Access**:  
   - Tailscale or WireGuard for secure VPN connectivity.  

---

## 6. Future Plans

- **Segment** DMZ or externally exposed services into separate VLAN if public-facing.  

---

## 7. Diagrams

- In progress
