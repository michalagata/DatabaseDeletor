
# RULE SET: 02_GLOBAL_BEST_PRACTICES
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## Global Best‑Practice Foundations (Integrate, Don’t List)
- **TOGAF**: Architecture Development Method (ADM) governs phased artifacts and traceability from business goals to technology choices.
- **DDD**: Model core domains and bounded contexts; strategic patterns (Context Map) + tactical patterns (Aggregates, Repositories, Domain Events).
- **12‑Factor App**: Config in env, stateless processes, disposability, logs as event streams, strict separation of build/release/run.
- **Clean Architecture**: Domain/business rules at the center; inward dependencies only; ports & adapters at the edge.
- **SRE (Google)**: SLIs/SLOs, error budgets, toil reduction, incident mgmt, capacity planning.
- **DevOps**: CI/CD, GitOps, IaC, immutable artifacts, fast feedback, trunk‑based or short‑lived branches, automated tests, security gates.
- **Cloud‑Native/On‑Prem**: Microservices or modular monolith when simpler; containers; **Kubernetes**; **service mesh** (mTLS, retries, circuit breaking); **event sourcing** and **sagas** where justified.