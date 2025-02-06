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
2. **Install `k9s`**
  - On MacOs, run: 
    ```bash
    brew install derailed/k9s/k9s
    ```
3. **Install Flux CLI**
   - On MacOS, run:
    ```bash
    brew install fluxcd/tap/flux
    ```
4. **Install Vault CLI**
   - On MacOS, run:
    ```bash
    brew tap hashicorp/tap
    brew install hashicorp/tap/vault
    ```
5. **Install Vault CLI**
   - On MacOS, run:
    ```bash
    brew install kubeseal
    ``` 


6. **Download Talos Linux**
   - For Proxmox, download the latest Talos release (e.g., `MetalAMD64.iso`) from [Talos Releases](https://github.com/siderolabs/talos/releases/tag/v1.9.1).

### Installation Notes
- Use the downloaded Talos ISO to create a VM in Proxmox.
- [Talos documentation for proxmox](https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/) .



# To-Do List for Proxmox and Kubernetes

## Proxmox VMs/LXC - High Availability Setup

- [x] OpenWrt 
- [x] Pi-hole (backup instance)
- [x] Home Assistant
- [x] Homebridge
- [x] Tailscale
- [x] Kubernetes Control Plane
- [x] Hashicorp Vault
- [x] UniFi

## Kubernetes Cluster Setup

- [ ] **Hashicorp Vault**
  - Deploy on a separate VM with multiple backups.
  - Integrate Kubernetes, KV (Key-Value store), and other secrets management.
  - Add MFA for enhanced security.

- [ ] **MetalLB**
  - Configure MetalLB to assign IP addresses in the range 10.0.0.100-199 for all services.
  - Ensure a static and predictable IP assignment to maintain sanity.

- [ ] **Kubernetes Dashboard**
  - Deploy and configure with the static IP: `10.0.0.100`.

- [ ] **Homepage**
  - Install and set up [Homepage](https://github.com/gethomepage/homepage) with the static IP: `10.0.0.101`.

- [ ] **Pi-hole Main**
  - Deploy the main Pi-hole instance in the cluster.

- [ ] **PGAdmin**
  - Deploy PGAdmin for PostgreSQL management.

- [ ] **Grafana**
  - Set up Grafana for monitoring and visualization.

- [ ] **Transmission**
  - Deploy Transmission for torrent management.

- [ ] **CommaFeed**
  - Deploy CommaFeed for RSS feed aggregation.

- [ ] **Wallabag**
  - Deploy Wallabag for managing and saving articles.

- [ ] **Linkding**
  - Set up Linkding for bookmark management.

- [ ] **n8n**
  - Deploy n8n for workflow automation.

- [ ] **VS Code-Server**
  - Install and configure the VS Code Server for remote development.

- [ ] **Obsidian Server**
  - Deploy Obsidian for note-taking and knowledge management.

- [ ] **Calibre-Web**
  - eBook collection for easy reading access..

- [ ] **Uptime Kuma**
  - Monitor the uptime of your services and websites with a clean UI.

- [ ] **Paperless-ngx**
  - Document scanning and management system for going paperless.
  
- [ ] **LLM-Services**
  -  AI language models for experimentation.
---

### Additional Notes
- Ensure proper backups and testing before making configurations live.
- Maintain documentation for each service to ensure replicability and troubleshooting.


### File Structure
```bash
Domum/
├── clusters/
│   └── production/          # Main cluster configs
│       ├── flux-system/     # Flux bootstrap
│       ├── infrastructure/  # Cluster-level services
│       │   ├── kube-vip/
│       │   ├── longhorn/
│       │   └── traefik/
│       ├── apps/            # User applications
│       │   ├── pihole/
│       │   ├── obsidian/
│       │   └── cert-manager/
│       └── sources/         # HelmRepositories
├── talos/                   # Talos machine configs
├── .gitignore
└── README.md

```