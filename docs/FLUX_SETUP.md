# Generate the PAT (Personal Access Token) in GitHub first.
flux bootstrap github \
  --owner=solosoyfranco \
  --repository=Domum \
  --branch=main \
  --path=cluster \
  --personal

Once complete, pull the changes to your local folder:
```bash
git pull origin main
``` 

(Flux will now watch your cluster/ folder in that repo and apply any YAML changes automatically.)