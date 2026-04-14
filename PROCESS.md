# Development Process

## Tools Used

- **Claude (claude.ai)** — primary development tool for all file generation,
  error diagnosis, and architecture decisions
- **helm** — local validation (lint, template, dependency update)
- **ansible-lint** — local playbook validation
- **kubeconform** — local manifest schema validation
- **nvim** — file editing

## Conversation Log

### Session 1 — Full project build

**Topic:** Complete infrastructure implementation from requirements.yaml

**What was asked:** Generate all Helm charts, Ansible playbook, CI pipeline,
traceability script following SDD requirements.

**What was accepted:**

- Overall project structure and file layout
- Helm chart templates for api, frontend, postgresql subcharts
- Ansible roles structure and task logic
- CI workflow with parallel jobs
- Traceability check script logic

**What was rejected or corrected:**

- Bitnami postgresql dependency — replaced with local subchart due to
  unreachable external repository
- `securityContext` placement — `allowPrivilegeEscalation` incorrectly placed
  at pod level, corrected to container level
- `.yamllint.yml` — initial config conflicted with ansible-lint requirements,
  added required `comments` and `octal-values` rules
- `namespace` variable in Ansible — reserved word, renamed to `k8s_namespace`
- Register variable names in Ansible roles — missing role prefix,
  added `deploy_` and `validate_` prefixes
- Helm template syntax — nvim auto-formatter inserted spaces inside `{{}}`,
  fixed with sed and editor configuration

## Timeline

1. Project structure creation — mkdir commands, empty file skeleton
2. api subchart — Chart.yaml, values.yaml, deployment, service, configmap, secret, helpers
3. frontend subchart — Chart.yaml, values.yaml, deployment, service, helpers
4. umbrella chart — Chart.yaml, values.yaml, ingress, helpers
5. helm dependency update — Bitnami 403, switched to local postgresql subchart
6. postgresql subchart — StatefulSet, service, secret, helpers
7. helm lint + helm template — fixed { { spacing bug, fixed {{ - spacing bug
8. Ansible — playbook, inventory, group_vars, deploy role, validate role
9. ansible-lint — fixed reserved variable, role prefixes, line length
10. CI pipeline — infra-ci.yml, .yamllint.yml
11. kubeconform — fixed securityContext split pod/container
12. yamllint + ansible-lint conflict — updated .yamllint.yml rules
13. demo/violation branch — 5 intentional violations, CI fails on traceability

## Key Decisions

**Local PostgreSQL subchart vs Bitnami**
Bitnami repository returned 403. Local subchart chosen — full control over
manifests, complete traceability, no external dependencies in CI.

**yamllint ignores charts/ directory**
Helm templates are not valid YAML — `{{-` syntax breaks yamllint. Ansible and
CI files are still linted. This is the standard approach for Helm projects.

**Credentials as environment variables**
`SDD_DB_USER` and `SDD_DB_PASSWORD` read via `lookup('env', ...)` in Ansible
group_vars. No passwords in any committed file.

## What the Developer Controlled

- Reviewed every generated file before committing
- Ran helm lint, helm template, ansible-lint, kubeconform locally before each push
- Caught and fixed: Bitnami connectivity issue, securityContext schema error,
  yamllint/ansible-lint config conflict, nvim formatter breaking Helm syntax,
  Ansible reserved variable name, missing role prefixes
- Verified demo/violation branch produces correct CI failures

## Course Corrections

| Issue                                   | How caught                    | Fix                                                      |
| --------------------------------------- | ----------------------------- | -------------------------------------------------------- |
| Bitnami 403                             | helm dependency update output | Local postgresql subchart                                |
| `allowPrivilegeEscalation` at pod level | kubeconform schema error      | Split into podSecurityContext / containerSecurityContext |
| `namespace` reserved in Ansible         | ansible-lint output           | Renamed to `k8s_namespace`                               |
| Missing role prefixes on register vars  | ansible-lint output           | Added `deploy_` and `validate_` prefixes                 |
| `{ { }}` spaces in templates            | helm template parse error     | sed fix + nvim config                                    |
| yamllint conflicts ansible-lint         | CI failure                    | Added comments + octal-values rules                      |

## Self-Assessment

**Traceability — PASS**
Every file has `@req` annotations. Enforcement script catches unannotated files
and orphan references. demo/violation branch proves it.

**DRY — PASS**
Labels defined once in `_helpers.tpl` per chart. All values in `values.yaml`.
Ansible variables centralized in `group_vars/all.yml`.

**Deterministic Enforcement — PASS**
All five CI checks run on every push. No manual steps required for validation.
traceability script exits 1 on any violation.

**Parsimony — PARTIAL**
Charts are minimal. Some duplication exists between umbrella `values.yaml` and
subchart `values.yaml` defaults — values are defined in both places. This could
be improved by removing defaults from subcharts and relying entirely on umbrella
overrides.
