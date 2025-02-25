# Longhorn HTTPS Access via Traefik with FluxCD on Talos

## Prerequisites
- Kubernetes cluster running **Talos Linux**
- **MetalLB** installed for LoadBalancer IPs
- **FluxCD** configured and running
- **Helm** installed
- `kubectl` configured
- **Longhorn** installed
- **Traefik** as the Ingress Controller
- **Cert-Manager** as the certificates manager w Cloudflare.

## Installation & Configuration

### **Apply Longhorn IngressRoute Configuration**
```sh
kubectl apply -f cluster/core/02-longhorn/ingress.yaml
```

### **Apply Middleware for Secure Headers**
```sh
kubectl apply -f cluster/core/02-longhorn/middleware.yaml
```

### **Apply Traefik Configuration**
```sh
kubectl apply -f cluster/core/04-traefik/values-configmap.yaml
```

### **Restart Traefik Deployment**
```sh
kubectl rollout restart deployment -n traefik
```
### **Optional: Delete Existing Traefik HelmRelease**
```sh
kubectl delete helmrelease traefik-release -n traefik
```

### **Optional: Reapply Traefik HelmRelease**
```sh
kubectl apply -f cluster/core/04-traefik/helmrelease.yaml
```

### **Verify Traefik & Longhorn Services**
```sh
kubectl get pods -n traefik
kubectl get pods -n longhorn-system
kubectl get svc -n longhorn-system
```
### **Check Longhorn IngressRoute**
```sh
kubectl get ingressroute -n longhorn-system
```

### **Test Access to Longhorn UI**
```sh
curl -k https://longhorn.lan.digitalcactus.cc
```

---

## **Verification & Troubleshooting**

### 🔹 **Check IngressRoute Logs**
```sh
kubectl describe ingressroute -n longhorn-system longhorn
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=100 | grep longhorn
```

### 🔹 **Ensure Longhorn Frontend Service is Reachable**
```sh
kubectl describe svc -n longhorn-system longhorn-frontend
```

### 🔹 **Check Running Pods**
```sh
kubectl get pods -n longhorn-system
kubectl get pods -n traefik
```

✅ **Longhorn UI should now be accessible via HTTPS at:**
```sh
https://longhorn.lan.digitalcactus.cc/#/dashboard
```


