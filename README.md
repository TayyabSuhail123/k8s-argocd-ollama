# AI Platform GitOps Case Study

**A production-grade, local Kubernetes AI inference platform with full GitOps automation**

This project bootstraps a secure, multi-node kind cluster and deploys an AI platform (Ollama, OpenWebUI, Prometheus) using ArgoCD as the single source of truth. All infrastructure and application state is managed declaratively via Git.

---

## What This Project Does

- **Bootstraps a 3-node kind Kubernetes cluster** with node isolation (control, general, inference)
- **Installs ArgoCD** for GitOps-driven deployment and management
- **Deploys hardened Helm charts** for Ollama (LLM inference), OpenWebUI (chat UI), and Prometheus (monitoring)
- **Applies strict security**: network policies, namespace isolation, non-root containers, RBAC, and no secrets in values.yaml
- **Enables true GitOps**: all changes are made via Git commits, ArgoCD syncs automatically, no manual `kubectl` or `helm` commands
- **Metrics and ServiceMonitors are disabled by default** for security and simplicity; can be enabled with a single value

---

## Architecture Overview

- **3-node kind cluster**: 1 control-plane, 2 workers (general, inference)
- **Node isolation**: 
  - General worker (`role=general`): OpenWebUI, Prometheus
  - Inference worker (`role=inference`): Ollama only (tainted)
- **Namespaces**: `argocd`, `ai-platform`, `monitoring`
- **Network policies**: Deny-all by default, explicit allow rules for only necessary traffic
- **ArgoCD**: All deployments and configuration managed via Git
- **No secrets in values.yaml**: All secrets are managed externally (e.g., SealedSecrets)

---

## Quick Start

### Prerequisites

- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/)
- (Optional) [argocd CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

Install on macOS:
```bash
brew install kind kubectl helm
```

### 1. Bootstrap the Cluster

```bash
cd ai-platform-case-study
chmod +x bootstrap/bootstrap.sh
./bootstrap/bootstrap.sh
```
This will:
- Create a 3-node kind cluster with node labels/taints
- Install ArgoCD
- Create namespaces and apply network policies

### 2. Access ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# In another terminal:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
- Open https://localhost:8080
- Username: `admin`
- Password: (output from above command)

### 3. Deploy the AI Platform

ArgoCD will automatically sync all applications defined in `/argocd/applications/`:
- Ollama (LLM inference)
- OpenWebUI (chat interface)
- Prometheus (monitoring, metrics disabled by default)

You can monitor sync status in the ArgoCD UI.

---

## Repository Structure

```
ai-platform-case-study/
├── README.md
├── bootstrap/           # Cluster and ArgoCD bootstrap scripts
├── charts/              # Hardened Helm charts for all services
├── argocd/
│   ├── applications/    # ArgoCD Application manifests (one per service)
│   └── infrastructure/  # Infra apps (metrics-server, sealed-secrets, etc)
└── .github/             # Hardening guidelines and dev instructions
```

---

## Security & Hardening

- **Network policies**: Deny-all by default, only allow required traffic (e.g., OpenWebUI → Ollama, Prometheus → metrics)
- **Namespace isolation**: Workloads separated by namespace
- **Non-root containers**: All pods run as non-root, with dropped Linux capabilities
- **RBAC**: Dedicated ServiceAccounts per service
- **No secrets in values.yaml**: All secrets are managed via SealedSecrets or other external tools
- **Resource limits**: All pods have CPU/memory requests and limits

---

## GitOps Workflow

- **All changes are made via Git**: No manual `kubectl apply` or `helm install`
- **ArgoCD auto-syncs**: Any commit to the repo is automatically applied to the cluster
- **No manual overrides**: All Helm values are managed in version control; Application manifests do not override chart defaults unless explicitly needed

---

## Enabling Metrics & Observability

- By default, `metrics.enabled: false` in all charts for security and simplicity
- To enable Prometheus metrics and ServiceMonitors:
  1. Install Prometheus CRDs:  
     `./bootstrap/install-prometheus-crds.sh`
  2. Set `metrics.enabled: true` in the relevant chart values (either in values.yaml or via ArgoCD Application manifest)
- ServiceMonitor resources are only created if metrics are enabled and CRDs are present

---

## Troubleshooting

- **ServiceMonitor/metrics errors**:  
  - Ensure `metrics.enabled: false` (default) or install Prometheus CRDs if enabling metrics
  - No Application manifest should override this unless you intend to enable metrics
- **Delete and recreate cluster**:
  ```bash
  kind delete cluster --name ai-platform-kind
  ./bootstrap/bootstrap.sh
  ```
- **Check ArgoCD logs**:
  ```bash
  kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
  ```
- **Verify network policies**:
  ```bash
  kubectl get networkpolicies -n argocd
  ```

---

## Production Migration Path

| Local Demo         | Production Equivalent                        |
|--------------------|---------------------------------------------|
| kind cluster       | EKS/GKE/AKS with multiple node groups       |
| K8s Secrets        | HashiCorp Vault + External Secrets Operator |
| Node labels/taints | GPU node pools with taints                  |
| NodePort services  | Ingress with TLS (cert-manager)             |
| Local storage      | Persistent volumes with CSI drivers         |
| Single ArgoCD      | HA ArgoCD with GitOps Bridge                |

---


