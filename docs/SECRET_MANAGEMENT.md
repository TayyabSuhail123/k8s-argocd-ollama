# Secret Management

This case study demonstrates GitOps-native secret management using **Sealed Secrets**. This document explains the approach and production alternatives.

## Current Implementation: Sealed Secrets

### Why Sealed Secrets?
- ✅ **GitOps-native**: Encrypted secrets safely committed to Git
- ✅ **No external dependencies**: Works in kind/air-gapped environments
- ✅ **Industry standard**: Maintained by Bitnami, widely adopted
- ✅ **Demonstrable**: Perfect for case studies and demos

### How It Works
1. **sealed-secrets controller** runs in the cluster (deployed via ArgoCD)
2. **SealedSecret** manifests are committed to Git (encrypted)
3. Controller decrypts SealedSecrets → creates regular Kubernetes Secrets
4. Applications consume the regular Secrets

### Architecture
```
┌─────────────────┐
│  Git Repository │
│  (Public Repo)  │
│                 │
│  ✅ Encrypted    │
│  SealedSecret   │
└────────┬────────┘
         │
         │ ArgoCD Sync
         ▼
┌─────────────────────────┐
│  Kubernetes Cluster     │
│                         │
│  ┌──────────────────┐  │
│  │ Sealed Secrets   │  │
│  │ Controller       │  │
│  └────────┬─────────┘  │
│           │             │
│           │ Decrypts    │
│           ▼             │
│  ┌──────────────────┐  │
│  │ Secret           │  │
│  │ (plaintext)      │  │
│  └────────┬─────────┘  │
│           │             │
│           │ Mounted     │
│           ▼             │
│  ┌──────────────────┐  │
│  │ OpenWebUI Pod    │  │
│  └──────────────────┘  │
└─────────────────────────┘
```

### Security Benefits
- 🔒 Secrets encrypted at rest in Git (safe to commit)
- 🔑 Only cluster controller can decrypt (private key never leaves cluster)
- 📝 Audit trail via Git history
- 🔄 Rotation via re-encryption and commit

---

## Production Alternatives

### 1. External Secrets Operator (Recommended for Production)

**Best for**: Cloud-native applications with centralized secret management

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: openwebui-secret
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: openwebui-secret
  data:
    - secretKey: webui-secret-key
      remoteRef:
        key: prod/openwebui/secret-key
```

**Benefits**:
- ✅ Centralized secret management (AWS Secrets Manager, Vault, GCP Secret Manager, Azure Key Vault)
- ✅ Automatic secret rotation
- ✅ Fine-grained access control and audit logs
- ✅ Multi-cluster support
- ✅ Secrets never stored in Git

**Trade-offs**:
- ❌ External dependency (cloud provider or Vault)
- ❌ Network calls to secret store
- ❌ More complex setup

**Use cases**:
- Multi-tenant platforms
- Regulated industries (PCI-DSS, HIPAA, SOC2)
- Teams needing centralized secret rotation
- Cross-cluster secret sharing

---

### 2. SOPS (Mozilla) + Age/KMS

**Best for**: GitOps-first teams, multi-cloud environments

```bash
# Encrypt entire secret file
sops --encrypt --age <public-key> secret.yaml > secret.enc.yaml

# Commit encrypted file to Git
git add secret.enc.yaml

# ArgoCD with SOPS plugin auto-decrypts during sync
```

**Benefits**:
- ✅ Git-based workflow (like Sealed Secrets)
- ✅ Multiple encryption backends (Age, AWS KMS, GCP KMS, Azure Key Vault, PGP)
- ✅ Can encrypt entire YAML files or just values
- ✅ Offline encryption support

**Trade-offs**:
- ❌ Requires ArgoCD plugin or Helm Secrets integration
- ❌ Key management complexity (Age keys or KMS setup)

**Use cases**:
- Multi-cloud deployments
- Teams wanting Git-based secrets with cloud KMS
- Infrastructure as Code workflows

---

### 3. HashiCorp Vault + ArgoCD Plugin

**Best for**: Enterprise, multi-team environments

```yaml
# values.yaml with Vault references
apiVersion: v1
kind: Secret
stringData:
  webui-secret-key: <path:vault/prod/openwebui#secret-key>
```

**Benefits**:
- ✅ Dynamic secrets (database credentials, API tokens)
- ✅ Secret leasing and automatic revocation
- ✅ Advanced access policies (multi-tenancy)
- ✅ Audit logging and compliance features
- ✅ Encryption as a service

**Trade-offs**:
- ❌ Complex infrastructure (Vault cluster, HA setup)
- ❌ Operational overhead (unsealing, backup/recovery)
- ❌ Requires ArgoCD Vault plugin

**Use cases**:
- Large enterprises with dedicated platform teams
- Multi-tenant SaaS platforms
- Dynamic credential management (databases, cloud APIs)
- Compliance-heavy environments

---

### 4. Native Kubernetes Secrets + GitOps (Not Recommended)

**Anti-pattern**: Storing base64-encoded secrets in Git

```yaml
# ❌ DON'T DO THIS
apiVersion: v1
kind: Secret
data:
  password: cGFzc3dvcmQxMjM=  # Just base64, not encrypted!
```

**Why it's bad**:
- ❌ base64 is encoding, NOT encryption
- ❌ Anyone with Git access can decode secrets
- ❌ Secrets exposed in Git history forever
- ❌ Violates security best practices

---

## Comparison Matrix

| Solution | GitOps Native | Encryption | Secret Rotation | External Deps | Complexity | Best For |
|----------|--------------|------------|-----------------|---------------|------------|----------|
| **Sealed Secrets** | ✅ Yes | ✅ Strong | Manual | None | Low | Demos, small teams, air-gapped |
| **External Secrets** | ⚠️ Partial | ✅ Strong | ✅ Automatic | Cloud/Vault | Medium | Production, cloud-native |
| **SOPS** | ✅ Yes | ✅ Strong | Manual | KMS (optional) | Medium | Multi-cloud, GitOps teams |
| **Vault** | ⚠️ Partial | ✅ Strong | ✅ Dynamic | Vault cluster | High | Enterprise, multi-tenant |

---

## Migration Path

If scaling this case study to production:

1. **Start with Sealed Secrets** (as implemented)
   - Simple, GitOps-native
   - No external dependencies

2. **Migrate to External Secrets Operator** when you need:
   - Centralized secret management
   - Automatic rotation
   - Multi-cluster deployments
   - Compliance/audit requirements

3. **Add Vault** when you need:
   - Dynamic secrets (database credentials)
   - Advanced multi-tenancy
   - Encryption as a service

---

## Implementation Guide (Sealed Secrets)

### Prerequisites
- Sealed Secrets controller deployed via ArgoCD
- `kubeseal` CLI installed locally

### Step 1: Install kubeseal CLI
```bash
# macOS
brew install kubeseal

# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz
sudo mv kubeseal /usr/local/bin/
```

### Step 2: Wait for Controller to Deploy
```bash
kubectl get pods -n kube-system | grep sealed-secrets
# Output: sealed-secrets-controller-xxxxx   1/1     Running
```

### Step 3: Generate Encrypted Secret
```bash
# Generate random secret and encrypt it
kubectl create secret generic openwebui-secret \
  --from-literal=webui-secret-key=$(openssl rand -base64 32) \
  --dry-run=client -o yaml --namespace=ai-platform | \
kubeseal --controller-namespace=kube-system \
  --controller-name=sealed-secrets-controller \
  --format=yaml
```

### Step 4: Update SealedSecret Template
Copy the `encryptedData` section from the output and update:
`charts/openwebui/templates/sealedsecret.yaml`

### Step 5: Commit and Push
```bash
git add charts/openwebui/templates/sealedsecret.yaml
git commit -m "chore: Update OpenWebUI encrypted secret"
git push
```

### Step 6: Verify Decryption
```bash
# Check if SealedSecret exists
kubectl get sealedsecret -n ai-platform

# Check if it created the regular Secret
kubectl get secret openwebui-secret -n ai-platform

# Verify OpenWebUI pod can read it
kubectl describe pod -n ai-platform -l app.kubernetes.io/name=openwebui
```

---

## Security Best Practices

### ✅ DO
- Generate strong random secrets (`openssl rand -base64 32`)
- Use namespace-scoped encryption (default with kubeseal)
- Rotate secrets periodically via re-encryption
- Store kubeseal public cert in CI/CD for automation
- Enable Sealed Secrets controller metrics and monitoring
- Backup the controller's private key (disaster recovery)

### ❌ DON'T
- Commit unencrypted secrets to Git
- Share kubeseal private keys (they never leave the cluster)
- Use weak/predictable secrets
- Store secrets in ConfigMaps
- Reuse secrets across environments (dev/staging/prod)

---

## Troubleshooting

### SealedSecret Not Decrypting
```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check SealedSecret events
kubectl describe sealedsecret openwebui-secret -n ai-platform
```

### Re-encrypt Existing Secret
```bash
# Fetch current secret value (if migrating)
kubectl get secret openwebui-secret -n ai-platform -o jsonpath='{.data.webui-secret-key}' | base64 -d

# Re-encrypt with new controller
kubectl create secret generic openwebui-secret \
  --from-literal=webui-secret-key="<value-from-above>" \
  --dry-run=client -o yaml --namespace=ai-platform | \
kubeseal --controller-namespace=kube-system \
  --controller-name=sealed-secrets-controller \
  --format=yaml
```

---

## References

- [Sealed Secrets GitHub](https://github.com/bitnami-labs/sealed-secrets)
- [External Secrets Operator](https://external-secrets.io/)
- [SOPS Documentation](https://github.com/mozilla/sops)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [ArgoCD Secret Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)
