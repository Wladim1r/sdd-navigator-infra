# SDD Navigator Infrastructure

Kubernetes deployment for the SDD Navigator stack: Rust API, PostgreSQL, nginx frontend.

## Architecture

- **API** — Rust service (`sdd-coverage`), serves `/healthcheck`, `/stats`, REST endpoints
- **Frontend** — nginx serving pre-built Next.js static export
- **PostgreSQL** — StatefulSet with PVC for data persistence
- **Ingress** — routes `/api/*` to API service, `/` to frontend

PostgreSQL is implemented as a local subchart (custom StatefulSet) rather than Bitnami
dependency — external Helm repositories were unreachable in the target environment,
and a local subchart gives full traceability over all manifests.

## Repository Structure

| Директория/файл       | Описание                        |
| --------------------- | ------------------------------- |
| charts/sdd-navigator/ | Helm umbrella chart             |
| charts/api/           | Rust API subchart               |
| charts/frontend/      | nginx frontend subchart         |
| charts/postgresql/    | PostgreSQL StatefulSet subchart |
| ansible/              | Deployment orchestration        |
| roles/deploy/         | Helm install + readiness wait   |
| roles/validate/       | Post-deploy health checks       |
| scripts/              | Enforcement tooling             |
| .github/workflows/    | CI pipeline                     |
| requirements.yaml     | SDD specification               |

## Running Helm Locally

```bash
helm dependency update charts/sdd-navigator/
helm lint charts/sdd-navigator/
helm template sdd-release charts/sdd-navigator/
```

## Running the Ansible Playbook

Requires: kubectl configured with cluster access, helm installed.

```bash
export SDD_DB_USER=myuser
export SDD_DB_PASSWORD=mypassword

ansible-playbook ansible/playbook.yml -i ansible/inventory/local.yml
```

## CI Pipeline

Five parallel jobs on every push:

| Job           | Tool                        | Checks                               |
| ------------- | --------------------------- | ------------------------------------ |
| helm-lint     | helm lint --strict          | Chart syntax and structure           |
| helm-validate | helm template + kubeconform | Manifests against Kubernetes schemas |
| ansible-lint  | ansible-lint                | Playbook quality and idempotency     |
| yamllint      | yamllint                    | YAML formatting                      |
| traceability  | check-traceability.sh       | @req annotations on all infra files  |

## CI Runs

- main (passing): <!-- paste link after first green run -->
- demo/violation (failing): <!-- paste link after violation run -->

## SDD Traceability

Every template, task, and CI job contains a `# @req SCI-XXX-NNN` comment referencing
`requirements.yaml`. Run enforcement locally:

```bash
bash scripts/check-traceability.sh
```
