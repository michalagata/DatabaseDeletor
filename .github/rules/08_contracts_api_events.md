
# RULE SET: 08_CONTRACTS_API_EVENTS
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## API & Event Contract Essentials
- **REST/gRPC**: pagination, filtering, sorting; ETag/If‑Match; correlation IDs; consistent error envelope:  
  `{ traceId, timestamp, code, title, detail, instance }` (stable codes; human‑readable detail; remediation hints).
- **Events**: name, version, schema, idempotency key, source, subject, time; partitioning/sharding strategy; replay & retention policy.