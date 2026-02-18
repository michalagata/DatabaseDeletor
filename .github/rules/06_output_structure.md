
# RULE SET: 06_OUTPUT_STRUCTURE
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## Output Structure (Always This Order)
1) **Overview** — intent, scope, business outcomes, measurable success metrics.  
2) **Assumptions & Constraints** — unknowns, pending decisions, external dependencies.  
3) **Stakeholders & RACI** — roles, responsibilities, escalation paths.  
4) **Business & Process View** — top use cases; **BPMN 2.0** (happy path + exceptions).  
5) **Architecture Views**  
   - **C4** Context + Container; key Components; UML sequence/state for behavior.  
   - **Deployment**: environments, regions, HA/DR (RTO/RPO), capacity model, multi‑tenancy.  
6) **Interfaces & Contracts** — **OpenAPI 3.1** (REST/gRPC) and **AsyncAPI** (events). Versioning, deprecation policy, error model, **idempotency** rules.  
7) **Requirements**  
   - **Functional** (use‑case scenarios + acceptance criteria)  
   - **NFR Matrix (ISO/IEC 25010)**: characteristic → metric → target → verification method.  
8) **Security & Privacy**  
   - Threat model (STRIDE/PASTA) → mitigations mapped to OWASP **ASVS**; maturity via **SAMM**; detections mapped to **ATT&CK**.  
   - GDPR data flows, data minimization, retention, DPIA triggers; **NIS2** obligations where applicable.  
9) **Ops Model & Governance** — SLIs/SLOs, on‑call, incident/change/release (**ITIL 4**), governance controls (**COBIT 2019**).  
10) **Quality Engineering** — unit/integration/e2e/perf/sec tests; test data mgmt; chaos/resilience drills.  
11) **Delivery & Runbook** — CI/CD stages, IaC, rollout (blue‑green/canary), rollback commands, smoke checks.  
12) **Cost & Sizing** — capacity assumptions, infra BOM, TCO (on‑prem/k8s).  
13) **Risks & Decisions** — risk register; **ADRs** with alternatives and consequences.  
14) **Changelog & Next Steps** — iteration plan, open questions.  
15) **Hallucination Check** — PASSED/NEEDS INPUT.