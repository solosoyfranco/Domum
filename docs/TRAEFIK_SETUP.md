# Traefik Installation on Talos with FluxCD

## Prerequisites
- Kubernetes cluster on Talos Linux
- Metallb
- FluxCD configured and running
- Helm installed
- `kubectl` configured

## Deploy Traefik

### 1. Create Namespace
```sh
kubectl apply -f cluster/core/04-traefik/namespace.yaml
```

### 2. Add Helm Repository
```sh
kubectl apply -f cluster/core/04-traefik/helmrepo.yaml
```

### 3. Deploy Traefik HelmRelease
```sh
kubectl apply -f cluster/core/04-traefik/helmrelease.yaml
```

### 4. Apply Middleware and Security Headers
```sh
kubectl apply -f cluster/core/04-traefik/default-headers.yaml
kubectl apply -f cluster/core/04-traefik/middleware.yaml
```

### 5. Configure Ingress for Dashboard
```sh
kubectl apply -f cluster/core/04-traefik/ingress.yaml
kubectl apply -f cluster/core/04-traefik/secret-dashboard.yaml
```

### 6. Apply Configuration Map
```sh
kubectl apply -f cluster/core/04-traefik/values-configmap.yaml
```

## Verification & Troubleshooting

### 1. Check Services
```sh
kubectl get svc -n traefik
```

### 2. Check Logs
```sh
kubectl logs -l app.kubernetes.io/name=traefik -n traefik --tail=100 -f
```

### 3. Check HelmRelease Status
```sh
kubectl get helmrelease traefik-release -n traefik
```

### 4. Test Access to Dashboard
```sh
curl -k https://traefik.domum.lan/dashboard/#/
```
Expected Output:
```
401 Unauthorized
```

### 5. Debug Issues
```sh
kubectl get pods -n traefik
kubectl port-forward -n traefik svc/traefik-release 8080:9000
```
Access dashboard: `http://localhost:8080/dashboard/`

### 6. Restart deployment (If Needed)
```sh
kubectl delete helmrelease traefik-release -n traefik
kubectl delete namespace traefik  
```

## Notes
- Ensure `traefik.domum.lan` resolves to `10.0.1.200`.
- If using Let's Encrypt, update TLS secret for `traefik.domum.lan`.

✅ **Traefik setup complete!** 🚀

