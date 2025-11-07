# Bootstrap Guide — Hardened Local Kubernetes Cluster

This folder contains the bootstrap layer for the AI Platform GitOps case study.

## Overview

The bootstrap process creates a **production-grade local Kubernetes environment** with:
- 3-node kind cluster (1 control-plane, 2 workers with role-based scheduling)
- Node isolation via labels and taints (inference workload separation)
- ArgoCD installed as the single source of truth for cluster state
- Network policies (deny-all by default, explicit allow rules)
- Namespace isolation for services

## Files

| File | Purpose |
|------|---------|
| `kind-cluster.yaml` | Kind cluster definition with node labels/taints for scheduling |
| `bootstrap.sh` | Automated setup script (cluster + ArgoCD installation) |
| `README.md` | This file - bootstrap documentation |

**Note:** ArgoCD is installed using the official manifest from GitHub. NetworkPolicies are intentionally **not applied to ArgoCD** - the control plane is trusted. Network isolation will be enforced at the workload layer (ai-platform, monitoring namespaces).

## Prerequisites

Install these tools before running bootstrap:

```bash
# macOS (Homebrew)
brew install kind kubectl helm

# Verify installations
kind version
kubectl version --client
helm version
```

## Node Architecture

The cluster has 3 nodes with specific roles:

1. **Control Plane** — Kubernetes control plane components only (no workloads)
2. **General Worker** (`role=general`) — OpenWebUI, Prometheus, supporting services
3. **Inference Worker** (`role=inference`) — Ollama only, with `NoSchedule` taint

This mirrors production patterns where GPU/inference nodes are isolated from general workloads.

## Usage

### 1. Run Bootstrap Script

```bash
# Make executable
chmod +x bootstrap/bootstrap.sh

# Run bootstrap (takes 2-3 minutes)
./bootstrap/bootstrap.sh
```

The script will:
- Create the kind cluster with node labels/taints
- Verify node readiness and configuration
- Create namespaces (argocd, ai-platform, monitoring)
- Install official ArgoCD manifest
- Apply network policies for ArgoCD namespace
- Display next steps

### 2. Verify Cluster State

After bootstrap completes, verify the setup:

```bash
# Check nodes and labels
kubectl get nodes --show-labels

# Verify taints on inference node
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Check ArgoCD pods
kubectl get pods -n argocd

# Verify namespaces
kubectl get namespaces
```

### 3. Access ArgoCD UI

```bash
# Port-forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# In another terminal, get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Open browser to https://localhost:8080
# Username: admin
# Password: <output from above command>
```

### 4. (Optional) Install ArgoCD CLI

```bash
# macOS
brew install argocd

# Login via CLI
argocd login localhost:8080
```

## Security Hardening Applied

### Node Isolation
- Control plane has no workload scheduling
- Worker nodes labeled: `role=general` and `role=inference`
- Inference node tainted: `role=inference:NoSchedule`
- Future Helm charts will use nodeSelector + tolerations

### Namespace Isolation
- Separate namespaces: `argocd`, `ai-platform`, `monitoring`
- Labeled for NetworkPolicy selection
- ArgoCD namespace is left open (trusted control plane)
- **NetworkPolicies will be applied in workload namespaces** (ai-platform, monitoring)

### Network Security (Applied in Workload Layer)
- Deny-all ingress by default in ai-platform and monitoring namespaces
- Explicit allow rules:
  - OpenWebUI → Ollama (port 11434)
  - Prometheus → Ollama metrics (port 9090)
  - Prometheus → OpenWebUI metrics
- DNS resolution allowed for all pods

## Next Steps

1. **Create Application Manifests** — Add ArgoCD Application/AppProject in `/argocd` directory
2. **Build Helm Charts** — Create hardened charts for Ollama, OpenWebUI, Prometheus in `/charts`
3. **Apply GitOps Workflow** — All deployments via Git commits → ArgoCD sync

## GitOps Principles

⚠️ **Never use imperative commands for application deployment:**
- ❌ `kubectl apply -f deployment.yaml`
- ❌ `helm install my-release ./chart`
- ✅ Commit manifests to Git → ArgoCD auto-syncs

ArgoCD is the single source of truth. All cluster state changes must be declarative and Git-managed.

## Troubleshooting

### Cluster already exists
```bash
kind delete cluster --name ai-platform-kind
./bootstrap/bootstrap.sh
```

### ArgoCD pods not starting
```bash
# Check events
kubectl get events -n argocd --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Cannot access ArgoCD UI
```bash
# Verify service exists
kubectl get svc -n argocd argocd-server

# Check port-forward is running
lsof -i :8080
```

## Production Considerations

This local setup demonstrates production patterns but is **not production-ready**. For real deployments:

- **Secrets Management** — Use Vault + External Secrets Operator (not plain K8s Secrets)
- **TLS/Ingress** — Configure Ingress with TLS termination (cert-manager)
- **HA ArgoCD** — Use HA installation manifest for redundancy
- **Resource Limits** — All pods need CPU/memory requests and limits
- **Monitoring** — Add Prometheus, Grafana, alerting
- **Backup/DR** — Velero for cluster backups, multi-region ArgoCD
- **RBAC** — Fine-grained permissions per team/namespace
- **Pod Security Standards** — Enforce restricted PSS on workload namespaces
