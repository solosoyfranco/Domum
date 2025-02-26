# Deploying Homepage on Kubernetes with Talos and FluxCD

## **Prerequisites**
- Kubernetes cluster running on Talos Linux
- Metallb configured for LoadBalancer support
- FluxCD installed and managing your cluster
- Helm and `kubectl` installed and configured

---

## **1. Add Helm Repository and Install Homepage**
First, add the Helm repository and install Homepage using Helm:

```sh
helm repo add jameswynn https://jameswynn.github.io/helm-charts
helm repo update
helm install homepage jameswynn/homepage -f values.yaml
```

---

## **2. Apply Configuration (values.yaml via ConfigMap)**
Create a ConfigMap to store the Helm values.

```sh
kubectl apply -f cluster/apps/services/homepage/configmap.yaml
```

```yaml
# cluster/apps/services/homepage/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: homepage-values
  namespace: default
  labels:
    app.kubernetes.io/name: homepage
    app.kubernetes.io/instance: homepage
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: "latest"
data:
  values.yaml: |
    service:
      type: LoadBalancer
      loadBalancerIP: 10.0.1.201
    persistence:
      enabled: true
      existingClaim: homepage-config
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000
    ingress:
      main:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: traefik-external
        hosts:
          - host: home.lan.digitalcactus.cc
            paths:
              - path: /
                pathType: Prefix
```

---

## **3. Create Persistent Volume Claim (Optional)**
This step ensures persistent storage for Homepage configurations.

```sh
kubectl apply -f cluster/apps/services/homepage/pvc.yaml
```

```yaml
# cluster/apps/services/homepage/pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: homepage-config
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

---

## **4. Apply IngressRoute for External Access**
Expose Homepage using Traefik.

```sh
kubectl apply -f cluster/apps/services/homepage/ingress.yaml
```

```yaml
# cluster/apps/services/homepage/ingress.yaml
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: homepage
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik-external
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`home.lan.digitalcactus.cc`) && PathPrefix(`/`)
      kind: Rule
      services:
        - name: homepage
          port: 3000
  tls:
    secretName: lan-digitalcactus-cc-tls
```

---

## **5. Deploy Homepage with Flux HelmRelease**
Deploy Homepage as a Flux-managed HelmRelease.

```sh
kubectl apply -f cluster/apps/services/homepage/helmrelease.yaml
```

```yaml
# cluster/apps/services/homepage/helmrelease.yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: homepage-release
  namespace: default
spec:
  chart:
    spec:
      chart: homepage
      sourceRef:
        kind: HelmRepository
        name: homepage-repo
      version: "latest"
  interval: 1m0s
  valuesFrom:
    - kind: ConfigMap
      name: homepage-values
```

---

## **6. Verify Deployment**
### **Check Pods**
```sh
kubectl get pods -n default
```

### **Check Services**
```sh
kubectl get svc -n default
```

### **Check Ingress**
```sh
kubectl get ingressroute -n default
```

### **Test Access**
```sh
curl -k https://home.lan.digitalcactus.cc
```
Expected Output:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Homepage</title>
  </head>
  <body>
    <h1>Welcome to Homepage</h1>
  </body>
</html>
```

---

## **7. Troubleshooting**
### **Check HelmRelease Status**
```sh
kubectl get helmrelease homepage-release -n default
```

### **Check Logs**
```sh
kubectl logs -l app.kubernetes.io/name=homepage -n default --tail=100 -f
```

### **Restart Deployment (If Needed)**
```sh
kubectl rollout restart deployment -n default
```

helm upgrade --install homepage jameswynn/homepage -f cluster/apps/services/homepage/values.yaml