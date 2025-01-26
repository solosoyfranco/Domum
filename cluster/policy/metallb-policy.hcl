# Allow read access to the metallb-webhook-cert secret
path "secret/metallb-webhook-cert" {
  capabilities = ["read", "list"]
}

# Allow listing all secrets in the secret/ KV engine
path "secret/metadata/*" {
  capabilities = ["list"]
}

# Allow reading policies (optional for debugging purposes)
path "sys/policies/acl/*" {
  capabilities = ["read", "list"]
}

# Allow listing secrets engines (optional for debugging purposes)
path "sys/mounts" {
  capabilities = ["read", "list"]
}