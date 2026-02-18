
# RULE SET: 03_ARCHITECTURE_PATTERNS
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## Architecture Defaults & Patterns
1. **Communication**
   - **Sync**: REST/HTTP (OpenAPI 3.1), gRPC where strong typing/latency matters.
   - **Async**: Messaging with RabbitMQ/Kafka/NATS. Define contracts with **AsyncAPI**.
   - **Idempotency**: Idempotency keys, deduplication; Outbox pattern for reliable event publishing.
   - **Backpressure & Retries**: Exponential backoff + jitter; DLQs; poison‑message handling.
2. **Mediator Pattern (Self‑Implemented)**
   - Organize domain requests as **Commands** (state change) and **Queries** (read‑only).
   - Mediator coordinates handlers; **no cross‑module chatter**; domain events publish side‑effects.
3. **CQRS**
   - Separate write and read models; eventual consistency for projections; reconciliation strategies.
4. **Event‑Driven**
   - **Event storming** to discover domain events. Version events; manage schema evolution. Use transactional outbox and **sagas** for orchestration.
5. **Security**
   - **AuthN/Z**: OIDC/OAuth2, Keycloak for RBAC/ABAC & multi‑tenancy; mTLS for service‑to‑service; least privilege.
   - **Secrets**: No secrets in code. Use vaults/Kubernetes Secrets + envelope encryption. Rotate regularly.
   - **Supply Chain**: SBOM (CycloneDX), image signing, provenance (SLSA goals), dependency pinning and scanning.
6. **Data**
   - Polyglot persistence when needed; migrations (Liquibase/Flyway), schema versioning.
   - Data quality rules, lineage, retention/classification; GDPR data subject rights workflows.
7. **Observability**
   - **OpenTelemetry** for traces/metrics/logs; exemplars; RED/USE dashboards; logs in JSON.
   - Synthetic checks, black‑box probes, chaos experiments.
8. **Performance & Resilience**
   - Capacity model, load shedding, caching (HTTP caching + CDN), bulkheads, circuit breakers.
9. **Documentation & Diagrams**
   - **C4** (Context/Container/Component/Code), UML sequence/state; ArchiMate for enterprise view.
   - Version diagrams with the code; keep **ADRs** in repo.
10. **Delivery & Operations**
   - **IaC**: Terraform/Ansible; **GitOps**: Argo CD/Flux; Helm/Helmfile/Kustomize.
   - Progressive delivery (blue‑green/canary); feature flags; runbooks and playbooks.