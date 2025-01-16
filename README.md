# Domum: A GitOps-Driven Homelab

## The Vision
Domum is a GitOps-driven homelab designed to integrate GitHub with a self-hosted Kubernetes cluster for seamless automated service deployments. This setup leverages Flux CD for continuous integration and deployment (CI/CD) workflows, with Prometheus and Grafana providing robust monitoring capabilities. The project showcases expertise in:

- **Infrastructure as Code (IaC):** Declarative and reproducible configurations.
- **Container Orchestration:** Efficient resource management and scaling.
- **Enterprise-Grade DevOps Practices:** Scalable and resilient design.

---

## Infrastructure Overview

### Network
- **Connection:** 1Gbps Fiber
- **Router:** OpenWRT
- **Switches and Access Points:** UniFi APs, Switches, and Cisco hardware

### Hardware
- **Servers:** 3x Proxmox nodes
- **Edge Devices:** 6x Raspberry Pi 5,4,3
- **Workstations:**
  - Fedora Workstation
  - Windows 11
  - macOS

---

## Tools and Setup

### Prerequisites
1. **Install `talosctl` (Talos CLI)**
   - On macOS, run:
     ```bash
     brew install siderolabs/tap/talosctl
     ```

2. **Download Talos Linux**
   - For Proxmox, download the latest Talos release (e.g., `MetalAMD64.iso`) from [Talos Releases](https://github.com/siderolabs/talos/releases/tag/v1.9.1).

### Installation Notes
- Use the downloaded Talos ISO to create a VM in Proxmox.
- [Talos documentation for proxmox](https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/) .

