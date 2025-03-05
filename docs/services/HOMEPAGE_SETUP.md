# Deploying Homepage on Kubernetes with Talos and FluxCD

## **Prerequisites**
- Kubernetes cluster running on Talos Linux
- Metallb configured for LoadBalancer support
- FluxCD installed and managing your cluster
- Helm and `kubectl` installed and configured

---

---

## **Apply Configuration**
Create a ConfigMap to store the Helm values.

```sh
kubectl apply -f cluster/apps/services/homepage/
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

## ** Troubleshooting**
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
