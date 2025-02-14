# Domum Homelab Architecture

This document provides a overview of the Domum homelab's architecture, including server roles, virtualization strategy, and core cluster design.

---

## 1. High-Level Diagram

Diagram illustrating the homelab's physical and logical layout: Proxmox hosts, Raspberry Pis, network segments, and so on.*

Example Diagram Outline:
```bash
Internet Gfiber
│
1 Gbps
│
▼
┌─────────────┐    ┌─────────────────┐
│  UniFi      │    │   Unifi Switch  │
│  (Router)   │───▶│   VLAN Trunk    │────▶ [Proxmox Node 1]
└─────────────┘    └─────────────────┘      [Talos BareMetal - Domum-X]
                                            [RPi4 - Domum-Xr2]
``` 
---

## 2. Physical Components

- **Proxmox**  
  - Lenovo Mq720
- **Talos Baremetal**
  - HP Prodesk mini G3 600
  - Lenovo Mq720  
- **Raspberry Pi (x6)**  
  - RPi 3/4/5 models for specialized workloads or edge services.

---

## 3. Virtualization & Containerization

### Proxmox VMs
- **Talos Linux**: Running the Kubernetes control-plane on at least 3 VMs (or mixed with RPi).  
- **LXC Containers**: Occasionally used for lightweight services not yet migrated to Kubernetes.  

### Kubernetes Cluster - in process of moving everything to baremetal
- **Control Plane**: 3 nodes (some combination of Proxmox VMs and/or RPi).  
- **Worker Nodes**: Additional baremetal or physical Pi's.  
- **Ingress**: Traefik or another ingress controller.  
- **Networking**: MetalLB or Kube-VIP for load-balancing service IP addresses.  

---

## 4. Services & GitOps Flow

1. **GitHub Repo (Domum)**:  
   - Contains all YAML/Helm definitions for the cluster.  
   - Committed changes trigger Flux CD to reconcile.
2. **Flux CD** (Kubernetes):  
   - Watches the `Domum` repo for updates.  
   - Applies new manifests or rolls back if needed.
3. **Applications**:
   - Vault, Pi-hole, Observability stack (Prometheus, Grafana), plus user services (e.g., Home Assistant, Linkding).

---

## 5. Storage Strategy

- **Longhorn** or **Ceph** (planned/optional) for distributed block storage.  
- **NFS or SMB** shares from a NAS (Unraid) for bulk file storage.  
- **Backups**: Google Cloud or local replication for all critical volumes (VM snapshots, etc.).

---

## 6. Security & Secrets Management

- **Vault** for handling sensitive credentials (database passwords, tokens, etc.).  
- **MFA** integration for sensitive services.  
- **TLS** certificates managed via cert-manager + Cloudflare DNS or ACME.

---

## 7. Monitoring & Logging

- **Prometheus** + **Grafana** for metrics.  
- **Loki** or **Elastic** for logs (future plan).  
- **Alertmanager** for email/Slack alerts.

---

## 8. Future Enhancements

- Additional Raspberry Pi nodes for scaled-out workloads.  
- Separate clusters for dev/test vs. production.  
- Enhanced CI/CD pipeline with testing or linting of Kubernetes manifests before merges.

---

## 9. Related Documentation

- [NETWORKING.md](./NETWORKING.md): Detailed VLAN & IP architecture.  
- [TALOS_SETUP.md](./TALOS_SETUP.md): Installation steps for Talos & cluster bootstrap.  
- [README.md](../README.md): Project overview, to-do list, and file structure.


### File Structure
```bash
Domum/
├── .gitignore
├── .sops.yaml                    # SOPS config (if using sealed secrets)
├── docs/
│   ├── ARCHITECTURE.md           # Cluster design decisions
│   ├── NETWORKING.md             # IP schema, VLANs, etc.
│   └── TALOS_SETUP.md            # Hardware-specific notes
└── cluster/
    ├── base/                     # Cross-environment resources
    │   ├── namespaces/
    │   ├── network-policies/
    │   └── crds/                # Custom Resource Definitions
    ├── core/                     # Critical cluster infrastructure
    │   ├── 01-talos/            # Talos machine configs
    │   │   ├── controlplane/
    │   │   │   ├── node-90.yaml # RPi-specific patches
    │   │   │   ├── node-91.yaml
    │   │   │   └── vip-config.yaml
    │   │   └── workers/
    │   ├── 02-flux/             # Flux bootstrap
    │   │   ├── kustomization.yaml
    │   │   └── gotk-components.yaml
    │   ├── 03-cert-manager/
    │   ├── 04-metallb/
    │   └── 05-longhorn/
    ├── apps/
    │   ├── _config/              # App defaults (helm values)
    │   ├── infra/                # Infrastructure apps
    │   │   ├── traefik/
    │   │   ├── vault/
    │   │   └── monitoring/       # (Prometheus, Grafana, etc)
    │   ├── services/             # User-facing apps
    │   │   ├── pihole/
    │   │   ├── obsidian/
    │   │   └── linkding/
    │   └── databases/
    │       ├── postgres/
    │       └── redis/
    ├── overlays/                # Environment-specific diffs
    │   ├── prod/
    │   └── homelab/            # Your current environment
    ├── scripts/                 # Helper scripts
    │   ├── talos-genconfig.sh
    │   └── flux-sync.sh
    └── tests/                   # Validation tests
        ├── kubeconform/
        └── talos-healthcheck/

```