# GitOps Pilot — Local GitOps Observability Platform

A free, local GitOps learning platform. It runs the dashboard on Kubernetes in Docker Desktop through kind, then uses Argo CD, Prometheus, Grafana, and Alertmanager to demonstrate the full GitOps workflow.

```text
GitHub PR → Actions (build + Trivy + manifest validation)
     ↓
Argo CD watches GitHub → local kind Kubernetes cluster synchronizes manifests
     ↓
Prometheus / Grafana / Alertmanager observe local workloads
```

## What you need

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with its Linux container engine running
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- Git and Node.js

No AWS account, cloud credentials, or cloud billing are required.

## Quick start

Open PowerShell in the repository folder and run:

```powershell
.\scripts\install-platform.ps1
```

The script creates a local kind cluster, builds and loads the dashboard image, installs Argo CD and the kube-prometheus-stack, and applies the initial alert rule.

## Open the services

Keep each port-forward command open in a separate terminal.

Dashboard:

```powershell
kubectl -n gitops-pilot port-forward service/gitops-pilot 3000:80
```

Open `http://localhost:3000`.

Grafana:

```powershell
kubectl -n monitoring port-forward service/kube-prometheus-stack-grafana 3001:80
```

Open `http://localhost:3001`.

Argo CD initial password:

```powershell
$encodedPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedPassword))
```

Start the Argo CD UI tunnel:

```powershell
kubectl -n argocd port-forward service/argocd-server 8080:443
```

Open `https://localhost:8080`; user name is `admin`.

## How GitOps works here

1. Change `k8s/app.yaml`, such as the replica count.
2. Commit and push the change to GitHub.
3. GitHub Actions validates Kubernetes YAML and scans the Docker image with Trivy.
4. Argo CD detects the Git change and synchronizes it to your local cluster.
5. Prometheus collects Kubernetes state metrics and Grafana makes them available for dashboards.

## Repository map

| Path | Purpose |
|---|---|
| `k8s/` | Namespace, Deployment, and Service |
| `gitops/argocd/` | Argo CD Application declaration |
| `monitoring/` | Prometheus/Grafana values and availability alert |
| `.github/workflows/` | Kubernetes validation and container security workflow |
| `scripts/install-platform.ps1` | One-command local installation |
| `kind-config.yaml` | Local Kubernetes cluster topology |

## Local dashboard only

For the lightweight dashboard without Kubernetes:

```powershell
npm start
```

The dashboard reloads the environments in `config/environments.yaml` when refreshed.
