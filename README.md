# GitOps Pilot — AWS Observability Platform

An AWS GitOps reference platform that deploys this dashboard to Amazon EKS and observes it with Prometheus, Grafana, and Alertmanager.

```text
GitHub PR → Actions (build + Trivy + manifest validation) → GHCR image
     ↓
Argo CD watches GitHub → EKS synchronizes Kubernetes manifests
     ↓
Prometheus / Grafana / Alertmanager observe and alert on workloads
```

## Repository map

| Path | Purpose |
|---|---|
| `terraform/` | AWS VPC and EKS infrastructure |
| `terraform/bootstrap/` | One-time encrypted/versioned S3 Terraform state bucket |
| `.github/workflows/` | Kubernetes validation and container security pipeline |
| `k8s/` | GitOps Pilot namespace, Deployment, and Service |
| `gitops/argocd/` | Argo CD Application that watches this repository |
| `monitoring/` | kube-prometheus-stack settings and alert rule |
| `scripts/` | Guided AWS/bootstrap installation commands |

## Local dashboard

```powershell
npm start
```

Open `http://localhost:3000`. The dashboard reads `config/environments.yaml` on refresh.

## AWS installation

> **Cost warning:** Amazon EKS, EC2 worker nodes, NAT gateways, and a Grafana LoadBalancer are billable. Run Terraform only in an AWS account you control.

### 1. Prerequisites

Install and authenticate the AWS CLI, Terraform, kubectl, Helm, Docker, and Git. Then confirm the intended AWS account:

```powershell
aws sts get-caller-identity
```

### 2. Create remote state

Create a protected S3 state bucket:

```powershell
cd terraform/bootstrap
terraform init
terraform apply
```

Copy the printed bucket name. Copy `terraform/backend.tf.example` to `terraform/backend.tf`, substitute the bucket name, and do not commit `backend.tf` if it contains account-specific settings.

### 3. Create EKS

```powershell
cd ../../terraform
terraform init
terraform plan
terraform apply
aws eks update-kubeconfig --region ap-south-1 --name gitops-pilot-development
kubectl get nodes
```

The default region is `ap-south-1`; update `terraform/variables.tf` if another AWS region is required.

### 4. Publish the container

Push the repository to GitHub. The **Build and scan container** action publishes `ghcr.io/srikanthmanikandan38/gitops-pilot:latest` and fails on high/critical Trivy findings. In GitHub package settings, ensure the package is accessible to your EKS cluster (public for a learning project, or configure an image pull secret for private use).

### 5. Install GitOps and monitoring

From the repository root:

```powershell
.\scripts\install-platform.ps1
```

This installs Argo CD, applies the Application declaration, installs the kube-prometheus-stack, and adds the initial availability alert. Change `monitoring/kube-prometheus-stack-values.yaml` before running it: never keep the sample Grafana password.

Retrieve the Argo CD administrator password:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
```

## How a deployment works

1. Change `k8s/app.yaml` (for example, a new image tag or replica count).
2. Commit and push the change to `main`.
3. GitHub Actions validates the manifest and scans the container.
4. Argo CD detects the Git change and reconciles it into the EKS cluster.
5. Prometheus records service metrics; Grafana displays them; Alertmanager sends configured alerts.

## Security defaults and next steps

- Remote Terraform state is encrypted, versioned, and blocked from public access. HashiCorp recommends S3 lockfiles; DynamoDB locking is deprecated. [Terraform S3 backend documentation](https://developer.hashicorp.com/terraform/language/backend/s3)
- Use IAM roles and EKS Pod Identity for workloads that need AWS permissions; do not place AWS keys in Kubernetes Secrets. [AWS EKS Pod Identity documentation](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
- Before production, use separate AWS accounts for development/staging/production, private EKS endpoints where suitable, a secrets manager, an ingress/TLS configuration, GitHub OIDC rather than long-lived AWS keys, and a non-default Argo CD administrator password.
