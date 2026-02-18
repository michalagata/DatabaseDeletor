# Project Context

Updated: 2026-02-18

## Tech Stack
- Backend: .NET 10 (latest), Minimal API, Dapper (NO EF Core)
- Frontend: Angular (latest stable), NG-ZORRO, SCSS + CSS variables
- Database (internal): PostgreSQL 16+ with pgvector
- Database (targets): SQL Server, PostgreSQL, MySQL, Oracle
- Messaging: RabbitMQ 3.13+ (MassTransit or Rebus)
- Cache: NONE (Redis FORBIDDEN per architecture.md)
- Logging: Serilog (structured, JSON)
- Observability: OpenTelemetry (traces, metrics, logs)
- Auth: Keycloak OIDC + SecretToken for admin
- AI Serving: vLLM / SGLang (on-premise, GPU)
- AI Training: PyTorch + PEFT + LoRA (Python)
- Container: Docker (BuildKit, split Dockerfiles, linux/amd64)
- Orchestration: Kubernetes
- Scheduling: Quartz.NET or Hangfire
- Testing: xUnit (>=80%), Playwright E2E, Testcontainers
- CI/CD: GitHub Actions

## Architecture
- Pattern: Clean Architecture with DDD, CQRS, EDA
- Layers: Domain -> Application -> Infrastructure -> Presentation
- Dependencies: Inward only
- Mediator: Custom implementation (NOT MediatR library)
- Events: Domain events via RabbitMQ (Transactional Outbox)

## Key Decisions (ADR-style)

### Decision: ADR-001 -- No Entity Framework Core
- **Date:** 2026-02-18
- **Context:** dotnet.md rule explicitly forbids EF Core
- **Decision:** Use Dapper and raw SQL for all data access
- **Alternatives considered:** EF Core (rejected per rules)
- **Consequences:** More SQL writing, better performance for bulk operations

### Decision: ADR-002 -- No Redis
- **Date:** 2026-02-18
- **Context:** architecture.md explicitly forbids Redis
- **Decision:** Use IMemoryCache or PostgreSQL for caching
- **Alternatives considered:** Redis (rejected per rules)
- **Consequences:** No distributed cache; acceptable for workload

### Decision: ADR-003 -- PostgreSQL as Primary Database
- **Date:** 2026-02-18
- **Context:** architecture.md mandates PostgreSQL as default
- **Decision:** PostgreSQL for app state, config, KB, training metadata
- **Consequences:** Must handle multiple DB dialects for deletion ops

### Decision: ADR-004 -- Custom Mediator (not MediatR)
- **Date:** 2026-02-18
- **Context:** dotnet.md mandates Mediator pattern but NOT MediatR NuGet
- **Decision:** Lightweight custom IMediator implementation
- **Consequences:** ~50 lines of code, full control

### Decision: ADR-005 -- vLLM for AI Serving
- **Date:** 2026-02-18
- **Context:** ai.md mandates vLLM or SGLang
- **Decision:** vLLM with OpenAI-compatible API
- **Consequences:** GPU hardware required, on-premise only

## Conventions
- English-only for all engineering artifacts
- CQRS command/query separation
- Feature toggles per API endpoint (appsettings.json)
- Config priority: DB > env vars > appsettings.{env}.json > appsettings.json
- Serilog structured JSON logging
- RFC 9457 Problem Details for errors
- i18n: EN/PL, runtime switching without page reload

## Integration Points
- NuGet: Artifactory at artifactory.anubisworks.net:82
- AI Models: HuggingFace Hub (download only)
- Training Data: Multiple open data sources (see Task.md section 6)
- Model Registry: MLflow (self-hosted)
- Monitoring: OpenTelemetry -> Prometheus/Grafana

## Known Constraints
- Redis FORBIDDEN
- EF Core FORBIDDEN
- Linux/amd64 ONLY (no ARM)
- Non-root containers ONLY
- GPU required for AI serving
- spec.txt and extend.txt do NOT exist in repo
- No source code exists yet -- greenfield project

### Decision: ADR-006 -- System.CommandLine 2.0.0-beta5.25306.1 API patterns
- **Date:** 2026-02-18
- **Context:** Need to use System.CommandLine for CLI; beta5 has breaking changes from beta4 and earlier
- **Decision:** Use the beta5 API surface as documented in the NuGet package XML docs
- **Key API patterns:**
  - `Option<T>(name, aliases)` — NO description parameter in constructor
  - `option.Description = "..."` — set description via property
  - `option.Required = true` — set required via property
  - `command.Add(option)` — add options via Add() method (not AddOption)
  - `command.SetAction(async (ParseResult result, CancellationToken ct) => ...)` — set handler via SetAction (NOT SetHandler)
  - `result.GetValue<T>(option)` / `result.GetRequiredValue<T>(option)` — get parsed values
  - `new CommandLineConfiguration(rootCommand)` — wrap command for invocation
  - `config.InvokeAsync(args, ct)` — invoke the command (NOT command.InvokeAsync)
  - `ParseResult.InvokeAsync(ct)` and `ParseResult.Invoke()` also available
  - No `Handler` property; use `Action` property or `SetAction()` method
- **Alternatives considered:** Older beta4 API (rejected, incompatible with installed version)
- **Consequences:** Must NOT use deprecated patterns (SetHandler, AddOption, description in Option ctor)
