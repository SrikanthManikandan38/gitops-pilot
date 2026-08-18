# GitOps Pilot

A compact, dependency-free MVP for a GitOps control plane. It provides an environment dashboard, sync trigger API, declarative environment catalog, Kubernetes starter manifest, and GitHub Actions validation workflow.

## Run locally

```powershell
npm start
```

Open `http://localhost:3000`.

## Delivery model

1. Change `config/environments.yaml` or `k8s/` in a pull request.
2. GitHub Actions validates the manifests.
3. A GitOps reconciler (Argo CD or Flux) watches the target branch and applies the approved state.
4. The dashboard exposes health and controlled sync requests. Replace its in-memory data provider with the reconciler API before production use.

## Production hardening

- Authenticate the UI and API with your identity provider; authorize production syncs separately.
- Use Argo CD/Flux as the reconciler; do not grant this service cluster-admin credentials.
- Add signed commits/images, admission policies (Kyverno/OPA), secrets through External Secrets or SOPS, and audit logging.
