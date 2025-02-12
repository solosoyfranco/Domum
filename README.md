# Domum: A GitOps-Driven Homelab

Domum is a GitOps-driven homelab that leverages **Talos Linux**, **Flux CD**, and **Kubernetes** to automate service deployments. This repository showcases how modern DevOps principles—Infrastructure as Code, CI/CD, and container orchestration—can be combined to create a **scalable**, **resilient**, and **self-documenting** homelab environment.

---

## 1. Vision & Key Features

- **Infrastructure as Code (IaC):** All configurations, from cluster provisioning to application deployments, are captured as declarative YAML.  
- **GitOps Workflow:** Flux CD continuously watches this repository for changes, applying them to the Kubernetes cluster automatically.  
- **Observability & Monitoring:** Prometheus and Grafana (planned or in-progress) to provide real-time insights into cluster health and performance.  
- **Enterprise-Grade DevOps Practices:** Emphasis on security, backups, and high availability through tools like Hashicorp Vault, MetalLB, etc.

---

## 2. Infrastructure Overview

### Network
- **1Gbps Fiber** connection  
- **Router:** OpenWRT  
- **Switches & APs:** UniFi, Cisco hardware

### Hardware
- **Proxmox Nodes (x3):** Primary compute infrastructure for VMs and LXC containers  
- **Raspberry Pis (x6):** For edge services, experimentation, or dedicated workloads  
- **Workstations:**
  - Fedora Workstation  
  - Windows 11  
  - macOS  

*For specific network subnets, VLANs, or hardware specs, see [docs/NETWORKING.md](./docs/NETWORKING.md) or [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md).*

---

## 3. Tools & Setup

### Prerequisites

1. **Talos CLI (`talosctl`), plus supporting tools**  
   - For macOS, an example installation:
     ```bash
     brew install talosctl kubectl helm fluxcd/tap/flux age sops
     ```

2. **Talos Linux ISO**  
   - Download the latest stable release ([Talos v1.9+](https://github.com/siderolabs/talos/releases))  
   - Refer to the official [Talos Proxmox Guide](https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/) for instructions on creating a VM.

> **For detailed installation steps** (Talos on Proxmox, node bootstrapping, etc.), see [docs/TALOS_SETUP.md](./docs/TALOS_SETUP.md).

---

## 4. Roadmap & To-Do

Below is a **living to-do list** covering both Proxmox-based VMs (as a transitional phase) and full Kubernetes deployments:

### Hardware/VM Tasks
- [ ] Migrate **OpenWRT** to kube-virt (currently on Proxmox)  
- [ ] Migrate **Home Assistant** to kube-virt  
- [ ] Migrate **Pi-hole** (backup instance) to the cluster  
- [ ] Convert **Homebridge**, **UniFi**, **Tailscale**, etc., to containers or kube-virt

### Kubernetes Cluster Setup
- [ ] **Hashicorp Vault**  
  - Multi-backup strategy, KV engine, MFA integration  
- [ ] **MetalLB**  
  - Allocate service IP range: `10.0.0.100-10.0.0.199`  
- [ ] **Kubernetes Dashboard** @ `10.0.0.100`  
- [ ] **Homepage** @ `10.0.0.101`  
- [ ] **Pi-hole (Main)**  
- [ ] **PGAdmin**  
- [ ] **Grafana** (plus Prometheus)  
- [ ] **Transmission**, **CommaFeed**, **Wallabag**, **Linkding**, etc.  
- [ ] **n8n** for workflow automation  
- [ ] **VS Code-Server** for remote development  
- [ ] **Obsidian Server** for knowledge management  
- [ ] **Calibre-Web** for eBook library  
- [ ] **Uptime Kuma** for service monitoring  
- [ ] **Paperless-ngx** for document management  
- [ ] **LLM-Services** for AI experimentation  

*(Future tasks and services can be appended as needed.)*

---

## 5. File Structure Overview

A high-level look at how this repository is organized:

```bash
Domum/
├── .gitignore
├── .sops.yaml                 # SOPS config (if using sealed secrets or encryption)
├── docs/
│   ├── ARCHITECTURE.md        # Notes on overall cluster design
│   ├── NETWORKING.md          # IP schema, VLANs, etc.
│   └── TALOS_SETUP.md         # Detailed Talos install guides
└── cluster/
    ├── base/                  # Environment-agnostic or "common" configs
    ├── core/                  # Critical cluster infrastructure (Talos configs, Flux, etc.)
    ├── apps/                  # Application definitions (Traefik, Pi-hole, Vault, etc.)
    ├── overlays/              # Environment-specific patches (dev, homelab, prod)
    ├── private/               # Sensitive data (encrypted or references to Vault)
    └── scripts/               # Helper scripts (talos-genconfig, flux-sync, etc.)
```
