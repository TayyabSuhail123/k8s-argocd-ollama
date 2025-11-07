# AI Platform Engineer Case Study

## Overview

In this case study, you will demonstrate your ability to deploy and operate AI infrastructure by
setting up a local Kubernetes environment running an LLM inference service. This exercise mirrors
real-world scenarios where our customers need to deploy the PhariaAI stack in their
environments with specific requirements for scalability, security, latency etc. You should allocate
approximately 3 hours to complete this task, focusing on creating a setup that demonstrates your
understanding of containerization, orchestration, and AI model deployment.

## Technical Requirements

Your task is to establish a local Kubernetes cluster (using minikube, kind or similar), deploy
Ollama for a containerized LLM inference service and connect Open WebUI to Ollama. Configure
the deployment to serve a lightweight model (such as Llama 3.2 3B or similar) that can run
efficiently on standard laptop hardware. Additionally, set up basic monitoring capabilities using
Kubernetes-native tools or solutions like Prometheus, and configure at least one security
measure such as network policies or service mesh integration to demonstrate production-
readiness considerations.

## Deliverables and Presentation

During the case study interview we'll discuss your solution in depth. We don't need a Powerpoint
presentation, but be prepared to explain:

• Your implementation approach and architecture options.
• Technical details such as cluster configuration, deployment strategy, resource
  optimization choices and how you would scale this solution for production use.
• Troubleshooting steps you took and performance considerations for the chosen model.
• How your setup addresses common operational concerns like updates, monitoring and
  disaster recovery.

During the follow-up interview, please demonstrate the running system while discussing potential
improvements and production deployment strategies.

---

## Implementation Checklist

### Core Requirements
- [x] Local Kubernetes cluster (kind with 3 nodes)
- [ ] Ollama deployment (LLM inference service)
- [ ] Open WebUI connected to Ollama
- [ ] Lightweight model deployed (Llama 3.2 3B)
- [ ] Basic monitoring (Prometheus)
- [ ] Security measures (NetworkPolicies)

### Production-Readiness Demonstrations
- [x] GitOps workflow (ArgoCD as single source of truth)
- [ ] Node isolation (inference workload on dedicated node)
- [ ] Resource optimization (requests/limits for laptop hardware)
- [ ] Security hardening (non-root, drop capabilities, RBAC)
- [ ] Observability (ServiceMonitors, metrics endpoints)
- [ ] Update strategy (rolling updates via Git commits)
- [ ] Disaster recovery approach (declarative manifests in Git)

### Interview Discussion Points
- Architecture decisions and alternatives
- Scaling strategy for production
- Performance tuning for the model
- Troubleshooting methodology
- Operational concerns (updates, monitoring, DR)
