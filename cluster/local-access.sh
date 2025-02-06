#!/bin/bash
# emergency-access.sh
kubectl -n traefik-system port-forward svc/traefik 8080:80 &
kubectl -n longhorn-system port-forward svc/longhorn-ui 8081:8000 &
echo "Access:"
echo "- Traefik: http://localhost:8080/dashboard/"
echo "- Longhorn: http://localhost:8081"