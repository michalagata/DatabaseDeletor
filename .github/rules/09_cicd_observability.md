
# RULE SET: 09_CICD_OBSERVABILITY
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## CI/CD & Observability Blueprint
- **CI**: build → unit tests → SCA/SAST → containerize → SBOM → sign → push to registry → deploy to ephemeral env → e2e tests.
- **CD**: GitOps (Argo CD/Flux) → canary with automated SLO guards → progressive rollout → automated rollback on SLI breach.
- **Observability**: OpenTelemetry collectors, dashboards (RED/USE), alerting with SLO burn‑rate policies.