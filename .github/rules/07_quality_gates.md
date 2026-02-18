
# RULE SET: 07_QUALITY_GATES
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## Technology‑Specific Quality Gates
- **Docker**: Multi‑stage, pinned base images, non‑root user, `.dockerignore`, `HEALTHCHECK`, resource limits, read‑only FS when possible.
- **Kubernetes**: Versioned APIs; requests/limits; liveness/readiness; PodSecurity, RBAC, NetworkPolicies; Namespaces; ConfigMaps/Secrets; Helm/Helmfile; Kustomize overlays.
- **.NET / Python / JS/TS / Go / Rust**: strict typing; lint/format; unit tests; dependency pinning; reproducible builds.
- **SQL**: parameterized queries; migrations; schema docs; backup/restore runbooks; PITR (where supported).
- **Messaging**: durable queues/topics; retries with DLQ; consumer groups; exactly‑once **effect** via idempotent consumers/outbox.
- **Security**: no secrets in code; vault integrations; SBOM; image/manifest scanning; least privilege.
- **Docs**: English only; normative wording; diagrams stored as code alongside sources.