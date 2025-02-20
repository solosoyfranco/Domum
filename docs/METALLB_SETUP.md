# Installing MetalLB on Talos Linux Using FluxCD

This guide provides step-by-step instructions to deploy **MetalLB** using **FluxCD and Helm** on **Talos Linux**.

## Prerequisites

Ensure you have:

- A working **Talos Linux** Kubernetes cluster.
- **FluxCD installed and configured**.
- **kubectl and talosctl configured** to interact with the cluster.
- A **static IP range** available for MetalLB.

## Step 1: Enable `strictARP` (Only if using IPVS mode)

If your cluster **uses kube-proxy in IPVS mode**, enable `strictARP`:

```sh
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

## Step 2: Create Namespace for MetalLB

```yaml
# cluster/networking/metallb/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
```

Apply the namespace:

```sh
kubectl apply -f cluster/networking/metallb/namespace.yaml
```

## Step 3: Create the HelmRepository for MetalLB

```sh
flux create source helm metallb-repo \
  --url=https://metallb.github.io/metallb \
  --namespace=metallb-system \
  --export > cluster/networking/metallb/helmrepo.yaml
```

Apply the HelmRepository:

```sh
kubectl apply -f cluster/networking/metallb/helmrepo.yaml
```

## Step 4: Deploy MetalLB using HelmRelease

```sh
flux create helmrelease metallb-release \
  --chart=metallb \
  --source=HelmRepository/metallb-repo \
  --chart-version=v0.14.9 \
  --namespace=metallb-system \
  --export > cluster/networking/metallb/helmrelease.yaml
```

Apply the HelmRelease:

```sh
kubectl apply -f cluster/networking/metallb/helmrelease.yaml
```

Verify that MetalLB is deployed:

```sh
kubectl get helmrelease metallb-release -n metallb-system
kubectl get pods -n metallb-system
```

## Step 5: Configure MetalLB with a **L2 Advertisement Pool**

Create an **IPAddressPool and L2Advertisement** file:

```yaml
# cluster/networking/metallb/config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.1.200-10.0.1.250 # Adjust this range based on your network

---

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec: {}
```

Apply the configuration:

```sh
kubectl apply -f cluster/networking/metallb/config.yaml
```

## Step 6: Verify MetalLB is Working

Check that the **MetalLB Controller and Speaker** are running:

```sh
kubectl get pods -n metallb-system
```

Ensure the **IP Address Pool is created**:

```sh
kubectl get ipaddresspools.metallb.io -n metallb-system
```

## Step 7: Test MetalLB with a LoadBalancer Service

Create a test **LoadBalancer** service:

```yaml
# cluster/networking/metallb/test-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: test-service
  namespace: default
spec:
  selector:
    app: nginx
  ports:
    - name: http
      port: 80
      targetPort: 80
  type: LoadBalancer
```

Apply the test service:

```sh
kubectl apply -f cluster/networking/metallb/test-service.yaml
```

Get the **External IP** assigned by MetalLB:

```sh
kubectl get svc test-service
```

