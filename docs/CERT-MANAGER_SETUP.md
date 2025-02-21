# Installing cert-manager on Talos Kubernetes with FluxCD

## Prerequisites
Ensure that you have the following tools installed and configured:

- Kubernetes cluster running Talos
- `kubectl` configured to interact with your cluster
- Helm installed
- FluxCD installed (if using GitOps approach)
- Traefik installed and running.

---

## Step 1: Create the cert-manager Namespace
```sh
kubectl apply -f cluster/core/05-cert-manager/namespace.yaml
```

### `namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
```

---

## Step 2: Manually Install cert-manager CRDs
Since we are managing CRDs manually, download and apply the latest CRDs:
- [Cert-manager latest CRDs](https://cert-manager.io/docs/releases/)
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml
```

Verify CRD installation:
```sh
kubectl get crds | grep cert-manager
```

---

## Step 3: Add cert-manager Helm Repository
```sh
kubectl apply -f cluster/core/05-cert-manager/helmrepo.yaml
```

### `helmrepo.yaml`
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: cert-manager-repo
  namespace: cert-manager
spec:
  interval: 1m0s
  url: https://charts.jetstack.io
```

---

## Step 4: Deploy cert-manager with HelmRelease
```sh
kubectl apply -f cluster/core/05-cert-manager/helmrelease.yaml
```

### `helmrelease.yaml`
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager-release
  namespace: cert-manager
spec:
  chart:
    spec:
      chart: cert-manager
      sourceRef:
        kind: HelmRepository
        name: cert-manager-repo
      version: v1.14.3
  interval: 1m0s
  values:
    installCRDs: false  # We are managing CRDs manually
    replicaCount: 3
    extraArgs:
      - --dns01-recursive-nameservers=1.1.1.1:53,9.9.9.9:53
      - --dns01-recursive-nameservers-only
    podDnsPolicy: None
    podDnsConfig:
      nameservers:
        - 1.1.1.1
        - 9.9.9.9
```

---

## Step 5: Verify Installation
### Check if cert-manager pods are running
```sh
kubectl get pods -n cert-manager
```

### Check cert-manager logs
```sh
kubectl logs -l app.kubernetes.io/name=cert-manager -n cert-manager --tail=100 -f
```

### Verify CRDs are installed
```sh
kubectl get crds | grep cert-manager
```

---

## Step 6: Troubleshooting
### If pods are not running, check events
```sh
kubectl get events -n cert-manager --sort-by=.metadata.creationTimestamp
```

### Describe a failing pod
```sh
kubectl describe pod <pod-name> -n cert-manager
```

### Restart cert-manager pods
```sh
kubectl rollout restart deployment cert-manager -n cert-manager
```

---

## Step 7: Configure ClusterIssuer for Let's Encrypt

Create the necessary files for issuers:
```sh
mkdir -p cluster/core/05-cert-manager/issuer
```

Create `letsencrypt-production.yaml` and `letsencrypt-staging.yaml`:
```sh
touch cluster/core/05-cert-manager/issuer/letsencrypt-production.yaml
```
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
      - dns01:
          cloudflare:
            email: your-cloudflare-email@example.com
            apiKeySecretRef:
              name: cloudflare-token-secret
              key: api-key
```

Apply the ClusterIssuer:
```sh
kubectl apply -f cluster/core/05-cert-manager/issuer/letsencrypt-production.yaml
```

---

## Step 8: Generate a TLS Certificate
Create the necessary certificate files:
```sh
mkdir -p cluster/core/05-cert-manager/certificates/production
```
```sh
touch cluster/core/05-cert-manager/certificates/production/lan-example-com.yaml
```

### Example certificate manifest:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: lan-example-com
  namespace: cert-manager
spec:
  secretName: lan-example-com-tls
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  dnsNames:
    - lan.example.com
```

Apply the certificate:
```sh
kubectl apply -f cluster/core/05-cert-manager/certificates/production/lan-example-com.yaml
```

Verify the challenge:
```sh
kubectl get challenges
```

Verify the certificate:
```sh
kubectl get certificate
```

---

## Useful References
- [TechnoTim Kubernetes Guide](https://technotim.live/posts/kube-traefik-cert-manager-le/)
- [Cert-manager Official Documentation](https://cert-manager.io/docs/releases/)
- [Cert-manager Installation Guide](https://cert-manager.io/docs/installation/)

