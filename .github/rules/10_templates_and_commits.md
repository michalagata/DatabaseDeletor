
# RULE SET: 10_TEMPLATES_AND_COMMITS
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## Templates
### ADR (Architecture Decision Record)
- **Title, Status, Context, Decision, Consequences (+/‑), Alternatives, References.**

### NFR Matrix (ISO/IEC 25010)
| Characteristic | Sub‑char | Metric | Target | Verification |
|---|---|---|---|---|

### Threat Model Skeleton
- **Assets, Entry points, Trust boundaries, Threats (STRIDE), Controls (ASVS), Residual risk, Detections (ATT&CK)**

### Example Git Commit (whenever code/manifests produced)
```bash
git add -A
git commit -m "Docs/Design: BRD+HLD+SRS; NFR(ISO 25010); Threat model (STRIDE/PASTA->ASVS/SAMM); APIs(OpenAPI/AsyncAPI); SRE(SLIs/SLOs); CI/CD(GitOps); ADRs"
```