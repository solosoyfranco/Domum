# Installing Longhorn on Talos Linux with Flux

## Prerequisites
- A running Kubernetes cluster on Talos Linux
- `kubectl`, `flux`, and `talosctl` installed
- Helm Controller and Flux configured

---

## Step 1: Create the Longhorn Namespace

```sh
kubectl apply -f cluster/core/02-longhorn/namespace.yaml
```

**Contents of `namespace.yaml`:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: longhorn-system
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
```

---

## Step 2: Add the Longhorn Helm Repository

```sh
flux create source helm longhorn-repo \
  --url=https://charts.longhorn.io \
  --namespace=longhorn-system \
  --export > cluster/core/02-longhorn/helmrepo.yaml
```

Apply the repository configuration:
```sh
kubectl apply -f cluster/core/02-longhorn/helmrepo.yaml
```

**Contents of `helmrepo.yaml`:**
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: longhorn-repo
  namespace: longhorn-system
spec:
  interval: 1m0s
  url: https://charts.longhorn.io
```

---

## Step 3: Deploy Longhorn using Flux HelmRelease

```sh
flux create helmrelease longhorn-release \
  --chart=longhorn \
  --source=HelmRepository/longhorn-repo \
  --chart-version=v1.8.0 \
  --namespace=longhorn-system \
  --export > cluster/core/02-longhorn/helmrelease.yaml
```

Apply the HelmRelease:
```sh
kubectl apply -f cluster/core/02-longhorn/helmrelease.yaml
```

**Contents of `helmrelease.yaml`:**
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: longhorn-release
  namespace: longhorn-system
spec:
  chart:
    spec:
      chart: longhorn
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: longhorn-repo
      version: v1.8.0
  interval: 1m0s
```

---

## Step 4: Verify Longhorn Deployment

Check the deployment status:
```sh
flux get helmrelease longhorn-release -n longhorn-system
```

Ensure all Longhorn pods are running:
```sh
kubectl get pods -n longhorn-system
```

Check if the storage class is created:
```sh
kubectl get storageclass
```

---

## Step 5: Patch Worker Nodes for Longhorn

To ensure Longhorn can properly mount and manage storage, apply the following patch to all worker nodes.

**Contents of `longhorn-patch.yaml`:**
```yaml
machine:
    kubelet:
        extraMounts:
          - destination: /var/lib/longhorn
            type: bind
            source: /var/lib/longhorn
            options:
              - bind
              - rshared
              - rw
```

Apply the patch to each worker node:
```sh
talosctl patch mc -p @cluster/core/01-talos/longhorn-patch.yaml -n 10.0.1.20,10.0.1.21,10.0.1.22
```

Repeat the above command for each worker node by changing the IP.

---

## Step 6: Access Longhorn UI

Once all the pods are running, expose the Longhorn UI using port forwarding:
```sh
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```
Now, access Longhorn UI at:
```
http://localhost:8080
```


