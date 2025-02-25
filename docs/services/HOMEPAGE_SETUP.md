# Deploying Homepage on Kubernetes with Talos and FluxCD

## **Prerequisites**
- Kubernetes cluster running on Talos Linux
- Metallb configured for LoadBalancer support
- FluxCD installed and managing your cluster
- Helm and `kubectl` installed and configured


## **Add Helm Repository**
```sh
kubectl apply -f cluster/apps/services/homepage/helmrepo.yaml
```

```yaml
# cluster/apps/services/homepage/helmrepo.yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: homepage-repo
  namespace: default
spec:
  interval: 1m0s
  url: https://gethomepage.github.io/homepage
```

## **Deploy Homepage with HelmRelease**
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
      version: "1.0.0"  # Use the latest version available
  interval: 1m0s
  valuesFrom:
    - kind: ConfigMap
      name: homepage-values
```

## **Configure Homepage Settings**
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
```

## **Create Persistent Volume Claim (Optional, if storing configurations persistently)**
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

## **Apply IngressRoute for External Access**
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
    - match: Host(`homepage.lan.digitalcactus.cc`) && PathPrefix(`/`)
      kind: Rule
      services:
        - name: homepage-release
          port: 80
  tls:
    secretName: lan-digitalcactus-cc-tls
```

## **Verify Deployment**
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
curl -k https://homepage.lan.digitalcactus.cc
```
Expected Output:
```
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

## **8. Troubleshooting**
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

