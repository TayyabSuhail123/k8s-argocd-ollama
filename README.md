# AI Platform GitOps Case Study

**Production-grade local Kubernetes deployment of an AI inference stack**

This repository demonstrates how to deploy and manage a local AI platform (Ollama + Open WebUI + Prometheus) on a kind cluster using **GitOps principles with ArgoCD as the single source of truth**.

## Project Status

🚧 **Phase 1: Bootstrap (Current)** — Cluster creation and ArgoCD installation  
🔜 **Phase 2: Core Services** — Helm charts for Ollama, OpenWebUI, Prometheus  
🔜 **Phase 3: GitOps Integration** — ArgoCD Applications and automated sync  
🔜 **Phase 4: Observability** — Metrics, dashboards, and monitoring

## Architecture Overview

### Infrastructure
- **3-node kind cluster** (1 control-plane, 2 workers)
- **Node isolation** via labels and taints:
  - Control plane: no workloads
  - General worker (`role=general`): OpenWebUI, Prometheus
  - Inference worker (`role=inference`): Ollama only (tainted)

### Security Hardening
- Network policies (deny-all by default, explicit allow rules)
- Namespace isolation (argocd, ai-platform, monitoring)
- Non-root containers with dropped capabilities
- Resource limits on all pods
- RBAC per service with dedicated ServiceAccounts

### GitOps Workflow
- **ArgoCD** manages all deployments
- **Git** is the single source of truth
- No imperative `kubectl apply` or `helm install` commands
- Automated sync and self-healing

## Repository Structure

```
ai-platform-case-study/
├── README.md                    # This file
├── .github/
│   └── copilot-instructions.md  # Development guidelines and hardening rules
└── bootstrap/                   # Phase 1: Cluster + ArgoCD setup
    ├── README.md               # Detailed bootstrap guide
    ├── kind-cluster.yaml       # Cluster definition with node labels/taints
    ├── bootstrap.sh            # Automated setup script
    └── argocd-install.yaml     # ArgoCD NetworkPolicies
```

## Quick Start

### Prerequisites

```bash
# macOS (Homebrew)
brew install kind kubectl helm

# Verify installations
kind version
kubectl version --client
```

### Phase 1: Bootstrap the Cluster

```bash
# Clone this repository
cd ai-platform-case-study

# Run bootstrap script
chmod +x bootstrap/bootstrap.sh
./bootstrap/bootstrap.sh
```

This will:
1. Create a 3-node kind cluster with proper node isolation
2. Install ArgoCD using the official manifest
3. Apply network policies for security hardening
4. Create namespaces (argocd, ai-platform, monitoring)

### Verify Installation

```bash
# Check cluster nodes and labels
kubectl get nodes --show-labels

# Verify ArgoCD is running
kubectl get pods -n argocd

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Development Principles

This case study follows production-grade practices for a local demo:

✅ **All infrastructure is declarative and version-controlled**  
✅ **ArgoCD is the only deployment mechanism** (no manual kubectl/helm)  
✅ **Security by default** (NetworkPolicies, RBAC, non-root containers)  
✅ **Node isolation** for workload separation (inference vs general)  
✅ **Comprehensive documentation** with production migration notes

See `.github/copilot-instructions.md` for detailed hardening guidelines.

## Next Steps

Once bootstrap is complete:

1. **Create Helm Charts** — Build hardened charts for Ollama, OpenWebUI, Prometheus
2. **ArgoCD Applications** — Define Application manifests in `/argocd` directory
3. **GitOps Workflow** — Commit changes → ArgoCD auto-sync
4. **Observability** — Add Prometheus ServiceMonitors and dashboards

## Production Migration Path

This local setup demonstrates patterns that scale to production:

| Local Demo | Production Equivalent |
|------------|----------------------|
| Kind cluster | EKS/GKE/AKS with multiple node groups |
| K8s Secrets | HashiCorp Vault + External Secrets Operator |
| Node labels/taints | GPU node pools with taints |
| NodePort services | Ingress with TLS (cert-manager) |
| Local storage | Persistent volumes with CSI drivers |
| Single ArgoCD instance | HA ArgoCD with GitOps Bridge |

## Troubleshooting

### Delete and recreate cluster
```bash
kind delete cluster --name ai-platform-kind
./bootstrap/bootstrap.sh
```

### Check ArgoCD logs
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Verify network policies
```bash
kubectl get networkpolicies -n argocd
```

## Contributing

This is a case study repository for demonstrating GitOps best practices. Each commit should:
- Have a clear description of the change
- Follow the hardening guidelines in `.github/copilot-instructions.md`
- Include necessary documentation updates

## License

MIT License - See LICENSE file for details
