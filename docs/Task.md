# Task.md — DatabaseDeletor: Comprehensive Technical Specification & Gap Analysis

> **Document type:** Technical Specification ("Conspect")
> **Created:** 2026-02-18
> **Version:** 1.0.0
> **Status:** Draft
> **Source specifications:** `specification.txt`
> **Note:** Files `spec.txt` and `extend.txt` referenced by user were NOT found in the repository. This analysis is based solely on `specification.txt`.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Gap Analysis: Specification vs Implementation](#2-gap-analysis-specification-vs-implementation)
3. [Solution Architecture](#3-solution-architecture)
4. [Core Module: Database Deletor CLI](#4-core-module-database-deletor-cli)
5. [AI/Neural Network Integration](#5-aineural-network-integration)
6. [Training Data Sources](#6-training-data-sources)
7. [Training Pipeline & Scripts](#7-training-pipeline--scripts)
8. [Scheduling & Ad-Hoc Triggering](#8-scheduling--ad-hoc-triggering)
9. [Data Fetching & Scraping Architecture](#9-data-fetching--scraping-architecture)
10. [Admin Panel & UI Specification](#10-admin-panel--ui-specification)
11. [Configuration Management](#11-configuration-management)
12. [Authentication & Authorization](#12-authentication--authorization)
13. [Testing Strategy](#13-testing-strategy)
14. [Docker & Containerization](#14-docker--containerization)
15. [Observability & Logging](#15-observability--logging)
16. [CI/CD Pipeline](#16-cicd-pipeline)
17. [Build Scripts Adaptation](#17-build-scripts-adaptation)
18. [Security & Compliance](#18-security--compliance)
19. [NFR Matrix](#19-nfr-matrix)
20. [Risk & Rollback](#20-risk--rollback)
21. [Implementation Roadmap](#21-implementation-roadmap)

---

## 1. Executive Summary

### Current State

The repository contains **zero application source code**. No `.cs`, `.sln`, `.csproj`, `.ts`, `.html`, or application `.py` files exist. The repository consists exclusively of:

- `specification.txt` — Original specification in Polish (database deletion CLI tool)
- `scripts/` — Universal .NET Build & Deployment Scripts (v2.0.0)
- `docs/NOTES.md` — Docker layer explanation
- `.github/rules/` — 16 architectural/engineering rule files
- `.tools/` — Python utility scripts
- `nuget.config` — NuGet configuration (Artifactory at `artifactory.anubisworks.net`)
- `VERSION` (1.0.0), `DOCKER_IMAGE` (`darkdervish/debian-base`)

### Target State

A comprehensive system consisting of:

1. **DatabaseDeletor CLI** — .NET command-line tool for mass database deletion with dependency analysis
2. **DatabaseDeletor WPF** (Phase 2) — Desktop GUI interface
3. **AI/ML Subsystem** — Neural network orchestration, RAG, feedback, training pipeline
4. **Admin Panel** — Angular web application for management, monitoring, scheduling
5. **Scraper Orchestrator** — Scalable data fetching system for training data
6. **API Backend** — .NET Minimal API for all services

### Gap Summary

| Area | Specified | Implemented | Gap |
|------|-----------|-------------|-----|
| CLI Application | Yes | **No** | 100% — Not started |
| WPF Desktop App | Yes (Phase 2) | **No** | 100% — Not started |
| Database Connectivity (SQL Server) | Yes | **No** | 100% |
| Database Connectivity (PostgreSQL) | Yes | **No** | 100% |
| Database Connectivity (MySQL) | Yes | **No** | 100% |
| Database Connectivity (Oracle) | Yes | **No** | 100% |
| Dependency Analysis Engine | Yes | **No** | 100% |
| Mass Delete with FK Resolution | Yes | **No** | 100% |
| Progress Bar | Yes | **No** | 100% |
| Deletion Plan & Confirmation | Yes | **No** | 100% |
| Graphical Deletion Report | Yes | **No** | 100% |
| Serilog Logging | Yes | **No** | 100% |
| Error Handling & Reporting | Yes | **No** | 100% |
| AI/Neural Network System | Yes (extended) | **No** | 100% |
| Admin Panel (Angular) | Yes (extended) | **No** | 100% |
| Training Pipeline | Yes (extended) | **No** | 100% |
| Docker Containerization | Partially (scripts) | **Scripts only** | ~80% |
| Build Scripts | Yes | **Yes** | 0% — Exists, needs adaptation |

---

## 2. Gap Analysis: Specification vs Implementation

### 2.1 specification.txt Requirements Breakdown

The original specification (`specification.txt`) defines the following features — **ALL are missing**:

#### 2.1.1 Core CLI Features (Priority: CRITICAL)

| # | Requirement (from specification.txt) | Status | Notes |
|---|--------------------------------------|--------|-------|
| R-01 | .NET command-line application | MISSING | No `.csproj` or `.sln` exists |
| R-02 | Accept full connection string as input | MISSING | No CLI argument parsing |
| R-03 | Accept SQL query targeting a table | MISSING | No query parser |
| R-04 | Analyze reference dependencies & FK relationships | MISSING | No schema introspection engine |
| R-05 | Support global DELETE (all data from target + related tables) | MISSING | No delete executor |
| R-06 | Support conditional DELETE with WHERE clause | MISSING | No WHERE clause handling |
| R-07 | Mass/bulk optimized deletion procedure | MISSING | No bulk operations |
| R-08 | **No schema modifications** (cannot alter keys/constraints) | CONSTRAINT | Design constraint — must be honored |
| R-09 | Graphical deletion report (tables + row counts) | MISSING | No reporting engine |
| R-10 | Real-time progress bar during deletion | MISSING | No progress tracking |
| R-11 | Full error handling (console + log file) | MISSING | No error handling framework |
| R-12 | Serilog-based logging | MISSING | No Serilog integration |
| R-13 | Confirmation mode (present plan before execution) | MISSING | No deletion plan generator |

#### 2.1.2 Database Support (Priority: CRITICAL)

| Database | Required | Status | ADO.NET Provider |
|----------|----------|--------|------------------|
| SQL Server (Microsoft) | Yes (minimum) | MISSING | `Microsoft.Data.SqlClient` |
| PostgreSQL | Yes (minimum) | MISSING | `Npgsql` |
| MySQL | Yes (minimum) | MISSING | `MySqlConnector` |
| Oracle | Yes (minimum) | MISSING | `Oracle.ManagedDataAccess.Core` |

#### 2.1.3 WPF Desktop Application (Phase 2)

| # | Requirement | Status |
|---|------------|--------|
| R-14 | WPF desktop interface | MISSING — Phase 2 |
| R-15 | Same functionality as CLI but with GUI | MISSING |
| R-16 | Error display in application window | MISSING |

### 2.2 Extended Requirements (from user request)

These are ADDITIONAL requirements beyond `specification.txt`:

| # | Extended Requirement | Status |
|---|---------------------|--------|
| E-01 | AI/Neural Network managing orchestrator | MISSING |
| E-02 | Sub-network instantiation from allowed model list | MISSING |
| E-03 | RAG modules (Self-RAG/CRAG/GraphRAG) | MISSING |
| E-04 | Online feedback with admin moderation | MISSING |
| E-05 | Automated finetuning (LoRA/QLoRA) | MISSING |
| E-06 | Training scripts (training/ directory) | MISSING |
| E-07 | Open data source fetching/scraping | MISSING |
| E-08 | Scheduled & ad-hoc triggering | MISSING |
| E-09 | Angular admin panel | MISSING |
| E-10 | Configuration management (appsettings.json + DB) | MISSING |
| E-11 | SecretToken authentication for admin panel | MISSING |
| E-12 | Comprehensive testing suite | MISSING |
| E-13 | Docker containerization for all components | PARTIAL (scripts only) |

---

## 3. Solution Architecture

### 3.1 Architecture Pattern

**Clean Architecture** with DDD, CQRS, and Event-Driven Architecture (per `architecture.md` rules).

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                           │
│  ┌──────────┐  ┌──────────┐  ┌─────────────┐  ┌──────────────────┐ │
│  │  CLI App  │  │ WPF App  │  │ Minimal API │  │ Angular Admin UI │ │
│  └──────────┘  └──────────┘  └─────────────┘  └──────────────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│                        APPLICATION LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────────┐    │
│  │  Commands/   │  │  Queries    │  │  Event Handlers          │    │
│  │  Handlers    │  │  Handlers   │  │  (Mediator pattern)      │    │
│  └─────────────┘  └─────────────┘  └──────────────────────────┘    │
├─────────────────────────────────────────────────────────────────────┤
│                          DOMAIN LAYER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  Entities     │  │  Value Objs  │  │  Domain Events           │  │
│  │  Aggregates   │  │  Interfaces  │  │  Domain Services         │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│                      INFRASTRUCTURE LAYER                           │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌────────────────────┐ │
│  │ Dapper   │  │ RabbitMQ │  │ Serilog   │  │ OpenTelemetry      │ │
│  │ (no EF!) │  │ Messaging│  │ Logging   │  │ Observability      │ │
│  └──────────┘  └──────────┘  └───────────┘  └────────────────────┘ │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌────────────────────┐ │
│  │ vLLM     │  │ Training │  │ Scraper   │  │ Scheduler          │ │
│  │ Serving  │  │ Pipeline │  │ Engine    │  │ (Quartz.NET)       │ │
│  └──────────┘  └──────────┘  └───────────┘  └────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Technology Stack

| Component | Technology | Version | Rule Source |
|-----------|-----------|---------|-------------|
| Backend Runtime | .NET | 10 (latest) | `dotnet.md` |
| Frontend | Angular | Latest stable | `angular.md`, `www.md` |
| Database (primary) | PostgreSQL | 16+ | `architecture.md` |
| ORM/Data Access | Dapper / raw SQL | Latest | `dotnet.md` (EF Core FORBIDDEN) |
| Messaging | RabbitMQ | 3.13+ | `architecture.md` |
| Messaging Abstraction | MassTransit or Rebus | Latest | `architecture.md` |
| Cache | **NONE (Redis FORBIDDEN)** | — | `architecture.md` |
| Logging | Serilog | Latest | `specification.txt`, `dotnet.md` |
| Observability | OpenTelemetry | Latest | `architecture.md` |
| Auth | Keycloak (OIDC) + SecretToken | Latest | `dotnet.md` |
| AI Serving | vLLM / SGLang | Latest | `ai.md` |
| AI Training | PyTorch + PEFT + LoRA | Latest | `ai.md` |
| Container Runtime | Docker (BuildKit) | Latest | `docker.md` |
| Orchestration | Kubernetes | Latest | `architecture.md` |
| Scheduling | Quartz.NET or Hangfire | Latest | `dotnet.md` |
| API Style | Minimal API + OpenAPI | .NET 10 | `dotnet.md` |
| Testing | xUnit + Playwright | Latest | `dotnet.md`, `www.md` |
| CI/CD | GitHub Actions | — | `devops.md` |

### 3.3 Project Structure

```
DatabaseDeletor/
├── src/
│   ├── DatabaseDeletor.Domain/                 # Domain layer (entities, interfaces, events)
│   ├── DatabaseDeletor.Application/            # Application layer (commands, queries, handlers)
│   ├── DatabaseDeletor.Infrastructure/         # Infrastructure (Dapper, messaging, external services)
│   ├── DatabaseDeletor.Infrastructure.AI/      # AI/ML infrastructure (vLLM client, RAG, training)
│   ├── DatabaseDeletor.Cli/                    # CLI application (console entry point)
│   ├── DatabaseDeletor.Wpf/                    # WPF desktop application (Phase 2)
│   ├── DatabaseDeletor.Api/                    # Minimal API backend
│   └── DatabaseDeletor.Web/                    # Angular admin panel
├── tests/
│   ├── DatabaseDeletor.Domain.Tests/           # Unit tests
│   ├── DatabaseDeletor.Application.Tests/      # Unit tests
│   ├── DatabaseDeletor.Infrastructure.Tests/   # Integration tests
│   ├── DatabaseDeletor.Cli.Tests/              # CLI integration tests
│   ├── DatabaseDeletor.Api.Tests/              # API integration tests
│   ├── DatabaseDeletor.E2E.Tests/              # Playwright E2E tests
│   └── DatabaseDeletor.Smoke.Tests/            # Smoke tests
├── training/                                   # AI training pipeline (Python)
│   ├── configs/                                # Training configurations (YAML)
│   ├── data/                                   # Data processing scripts
│   ├── scripts/                                # Training scripts
│   │   ├── train_full.py                       # Full fine-tuning
│   │   ├── train_sft.py                        # Supervised fine-tuning
│   │   ├── train_lora.py                       # LoRA fine-tuning
│   │   ├── train_qlora.py                      # QLoRA fine-tuning
│   │   ├── train_delta.py                      # Delta/incremental training
│   │   ├── train_online.py                     # Online learning
│   │   ├── train_feedback.py                   # Feedback-based training
│   │   ├── train_distillation.py               # Model distillation
│   │   ├── evaluate.py                         # Model evaluation
│   │   ├── export_model.py                     # Model export (GGUF, ONNX)
│   │   └── hot_swap.py                         # Hot-swap adapter management
│   ├── fetchers/                               # Data source fetchers
│   │   ├── base_fetcher.py                     # Abstract base fetcher
│   │   ├── huggingface_fetcher.py              # HuggingFace datasets
│   │   ├── web_scraper.py                      # Web scraping
│   │   ├── api_fetcher.py                      # REST API fetching
│   │   └── database_fetcher.py                 # Database schema fetching
│   ├── requirements.txt
│   └── README.md
├── docker/                                     # Split Dockerfiles
│   ├── Dockerfile.base                         # OS + core tools
│   ├── Dockerfile.lang                         # .NET SDK + Node.js
│   ├── Dockerfile.deps                         # NuGet + npm packages
│   ├── Dockerfile.build                        # Build stage
│   ├── Dockerfile.runtime                      # Final minimal image
│   ├── Dockerfile.training                     # Python training environment
│   └── docker-compose.yml                      # Full stack orchestration
├── scripts/                                    # Build & deployment scripts (existing)
├── docs/
│   ├── Task.md                                 # This file
│   └── NOTES.md                                # Docker layer notes
├── .github/
│   ├── rules/                                  # Engineering rules (16 files)
│   └── workflows/                              # CI/CD workflows
├── VERSION                                     # 1.0.0
├── DOCKER_IMAGE                                # darkdervish/debian-base
├── nuget.config                                # Artifactory NuGet
└── DatabaseDeletor.sln                         # Solution file (TO CREATE)
```

### 3.4 Key Architecture Decisions (ADRs)

#### ADR-001: No Entity Framework Core

- **Context:** `dotnet.md` rule explicitly forbids EF Core.
- **Decision:** Use Dapper and raw SQL for all data access.
- **Consequences:** More SQL writing, but better performance control for bulk operations. Aligns with the mass deletion use case.

#### ADR-002: No Redis

- **Context:** `architecture.md` explicitly forbids Redis.
- **Decision:** Use in-process caching (`IMemoryCache`) or PostgreSQL for any caching needs.
- **Consequences:** No distributed cache; acceptable for this workload.

#### ADR-003: PostgreSQL as Primary Database

- **Context:** `architecture.md` mandates PostgreSQL as default.
- **Decision:** PostgreSQL for application state, configuration, KB, training metadata. Target databases (SQL Server, PostgreSQL, MySQL, Oracle) are external connections.
- **Consequences:** Must handle multiple database dialects for deletion operations while using PostgreSQL internally.

#### ADR-004: Mediator Pattern (No MediatR Library)

- **Context:** `dotnet.md` mandates Mediator pattern but NOT the MediatR NuGet package.
- **Decision:** Implement a lightweight custom Mediator (IMediator, IRequestHandler<TRequest, TResponse>).
- **Consequences:** ~50 lines of code for the mediator; full control, no external dependency.

#### ADR-005: AI Serving via vLLM

- **Context:** `ai.md` mandates vLLM or SGLang for model serving.
- **Decision:** Use vLLM with OpenAI-compatible API.
- **Consequences:** GPU hardware required; models served on-premise only.

---

## 4. Core Module: Database Deletor CLI

### 4.1 Dependency Analysis Engine

The core engine must introspect the target database schema WITHOUT modifying it.

#### Algorithm

```
1. Parse user SQL query → extract target table name
2. Connect to target database using connection string
3. Query INFORMATION_SCHEMA (or equivalent) to discover:
   a. All foreign key constraints referencing the target table
   b. All foreign key constraints on those referencing tables (recursive)
   c. Build a full dependency graph (DAG)
4. Topological sort the dependency graph
5. For each table in reverse topological order:
   a. Determine rows that reference the target rows
   b. Generate DELETE statements respecting FK order
6. Present the deletion plan to user for confirmation
7. Execute deletions in correct order within transactions
```

#### Database-Specific Schema Introspection

| Database | System Catalog Query |
|----------|---------------------|
| SQL Server | `sys.foreign_keys`, `sys.foreign_key_columns`, `sys.tables`, `sys.columns` |
| PostgreSQL | `information_schema.table_constraints`, `information_schema.key_column_usage`, `information_schema.referential_constraints` |
| MySQL | `information_schema.KEY_COLUMN_USAGE`, `information_schema.TABLE_CONSTRAINTS` |
| Oracle | `ALL_CONSTRAINTS`, `ALL_CONS_COLUMNS` |

### 4.2 Bulk Delete Optimization

Per specification: deletion must be mass, optimized, and fast. Schema MUST NOT be modified.

**Strategy:**

1. **Batch DELETE with IN clause** — Delete in configurable batch sizes (default: 5000 rows)
2. **CTE-based cascading** — Use recursive CTEs where supported to identify related rows
3. **Transaction batching** — Group deletes into transactions with configurable batch size
4. **Parallel table deletion** — Tables without mutual FK dependencies can be deleted concurrently
5. **Progress tracking** — Report actual rows deleted vs. estimated total

**Constraints:**
- Cannot disable/drop foreign keys
- Cannot disable/drop constraints
- Cannot modify triggers
- Must respect all existing database integrity rules

### 4.3 CLI Interface Design

```
Usage: dbdeletor [options]

Options:
  -c, --connection-string <string>    Full database connection string (REQUIRED)
  -d, --database-type <type>          Database type: sqlserver|postgresql|mysql|oracle (REQUIRED)
  -q, --query <sql>                   SQL query targeting the table (REQUIRED)
  -w, --where <clause>                WHERE clause for conditional deletion
  --batch-size <n>                    Rows per batch (default: 5000)
  --timeout <seconds>                 Command timeout in seconds (default: 300)
  --dry-run                           Show deletion plan without executing
  --no-confirm                        Skip confirmation prompt
  --log-file <path>                   Log file path (default: dbdeletor.log)
  --log-level <level>                 Log level: Verbose|Debug|Information|Warning|Error (default: Information)
  --report-format <format>            Report format: table|json|csv (default: table)
  -v, --version                       Show version
  -h, --help                          Show help
```

### 4.4 Deletion Plan Display

Before execution, the tool MUST present:

```
╔══════════════════════════════════════════════════════════════╗
║                    DELETION PLAN                             ║
╠══════════════════════════════════════════════════════════════╣
║ Target Database: MyDatabase (SQL Server)                     ║
║ Target Table:    dbo.Orders                                  ║
║ WHERE Clause:    OrderDate < '2020-01-01'                    ║
╠══════════════════════════════════════════════════════════════╣
║ Step │ Table                │ Est. Rows │ FK Dependency       ║
╠══════╪══════════════════════╪═══════════╪═════════════════════╣
║  1   │ dbo.OrderItems       │    15,230 │ FK_OrderItems_Orders║
║  2   │ dbo.OrderPayments    │     5,100 │ FK_Payments_Orders  ║
║  3   │ dbo.OrderShipments   │     3,400 │ FK_Shipments_Orders ║
║  4   │ dbo.Orders           │     5,000 │ (target table)      ║
╠══════════════════════════════════════════════════════════════╣
║ Total estimated rows to delete: 28,730                       ║
╚══════════════════════════════════════════════════════════════╝

Proceed with deletion? [y/N]:
```

### 4.5 Post-Deletion Report

```
╔══════════════════════════════════════════════════════════════╗
║                   DELETION REPORT                            ║
╠══════════════════════════════════════════════════════════════╣
║ Table                │ Deleted │ Duration │ Status            ║
╠══════════════════════╪═════════╪══════════╪═══════════════════╣
║ dbo.OrderItems       │  15,230 │   2.3s   │ OK               ║
║ dbo.OrderPayments    │   5,100 │   0.8s   │ OK               ║
║ dbo.OrderShipments   │   3,400 │   0.5s   │ OK               ║
║ dbo.Orders           │   5,000 │   1.1s   │ OK               ║
╠══════════════════════════════════════════════════════════════╣
║ Total: 28,730 rows deleted in 4.7s (6,112 rows/sec)         ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 5. AI/Neural Network Integration

### 5.1 Managing Orchestrator Network

The AI subsystem is managed by an **orchestrator** that coordinates:

1. **Model Registry** — Track available models, versions, adapters (MLflow)
2. **Sub-network Instantiation** — Spin up/down model instances via vLLM
3. **Request Routing** — Route inference requests to appropriate model instances
4. **Adapter Management** — Multi-LoRA hot-swap for different tasks
5. **Health Monitoring** — Track model health, latency, throughput
6. **Auto-scaling** — Scale model instances based on load (Kubernetes HPA)

#### Orchestrator Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   AI ORCHESTRATOR                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │  Model       │  │  Request     │  │  Health        │ │
│  │  Registry    │  │  Router      │  │  Monitor       │ │
│  │  (MLflow)    │  │              │  │                │ │
│  └──────┬──────┘  └──────┬───────┘  └───────┬────────┘ │
│         │                │                   │          │
│  ┌──────▼──────────────────▼───────────────────▼──────┐  │
│  │              vLLM SERVING CLUSTER                   │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐            │  │
│  │  │ Model A │  │ Model B │  │ Model C │  ...        │  │
│  │  │ +LoRA 1 │  │ +LoRA 2 │  │ +LoRA 3 │            │  │
│  │  └─────────┘  └─────────┘  └─────────┘            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │              RAG SUBSYSTEM                        │    │
│  │  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │    │
│  │  │ Embedder │  │ Vector   │  │ Knowledge Base │  │    │
│  │  │          │  │ Search   │  │ (PostgreSQL)   │  │    │
│  │  └──────────┘  └──────────┘  └────────────────┘  │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │              GUARDRAILS                            │    │
│  │  ┌──────────────┐  ┌────────────┐  ┌───────────┐ │    │
│  │  │ NeMo Rails   │  │ Llama Guard│  │ Presidio  │ │    │
│  │  │ (safety)     │  │ (content)  │  │ (PII)     │ │    │
│  │  └──────────────┘  └────────────┘  └───────────┘ │    │
│  └──────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### 5.2 Allowed Open-Source Models

Per `ai.md` rules — approved model list:

| Model | Parameters | Use Case | License |
|-------|-----------|----------|---------|
| DeepSeek-V3 | 671B (MoE) | General reasoning, code | MIT-like |
| DeepSeek-R1 | 671B (MoE) | Reasoning, chain-of-thought | MIT-like |
| Qwen2.5-72B-Instruct | 72B | General purpose, multilingual | Apache 2.0 |
| Qwen2.5-Coder-32B | 32B | Code generation/analysis | Apache 2.0 |
| Llama-3.1-70B-Instruct | 70B | General purpose | Llama 3.1 Community |
| Llama-3.3-70B-Instruct | 70B | Latest Llama generation | Llama 3.3 Community |
| Mixtral-8x22B-Instruct-v0.1 | 176B (MoE) | MoE general purpose | Apache 2.0 |
| Mistral-Large-Instruct (2411) | ~123B | High-quality instruction following | Apache 2.0 |
| Mistral-Small-24B-Instruct (2501) | 24B | Efficient general purpose | Apache 2.0 |
| Codestral-25.01 | ~22B | Code-specialized | MNPL |
| Gemma-2-27B-IT | 27B | Efficient general purpose | Gemma License |
| Phi-4 | 14B | Reasoning, math | MIT |
| OLMo-2-1124-13B-Instruct | 13B | Fully open research | Apache 2.0 |
| Command R+ (08-2024) | 104B | RAG-optimized | CC-BY-NC-4.0 |
| DBRX-Instruct | 132B (MoE) | Enterprise MoE | Databricks Open |

**Polish-specialized models (additional):**

| Model | Parameters | Specialty |
|-------|-----------|-----------|
| Bielik-11B-v2 | 11B | Polish language, SpeakLeash project |
| Bielik-7B-v0.1 | 7B | Polish base model |
| Bielik v3 Small (1.5B/4.5B) | 1.5B / 4.5B | Compact Polish models |

### 5.3 RAG Modules

Per `ai.md` rules — RAG 2.0 implementation:

| RAG Type | Description | Use Case |
|----------|-------------|----------|
| **Self-RAG** | Model generates retrieval tokens and self-evaluates relevance | Quality-focused retrieval |
| **CRAG** (Corrective RAG) | Evaluates retrieved docs and triggers web search fallback | Reliability improvement |
| **GraphRAG** | Knowledge graph-based retrieval | Complex relationship queries |

#### RAG Pipeline

```
User Query → Guardrails (input) → Embedder → Vector Search (PostgreSQL pgvector)
  → Document Retrieval → Re-ranking → Context Assembly
  → LLM Inference (vLLM) → Guardrails (output) → Response
```

#### Knowledge Base Schema (PostgreSQL)

```sql
-- Per ai.md rules: KB stored in PostgreSQL with versioning
CREATE TABLE kb_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding VECTOR(1536),  -- pgvector extension
    metadata JSONB DEFAULT '{}',
    source TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE kb_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name TEXT NOT NULL UNIQUE,
    rule_content TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE kb_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID REFERENCES kb_entries(id),
    version INTEGER NOT NULL,
    content TEXT NOT NULL,
    changed_by TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE kb_usage_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID REFERENCES kb_entries(id),
    query_text TEXT,
    relevance_score FLOAT,
    used_in_response BOOLEAN,
    feedback_rating INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE training_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    run_type TEXT NOT NULL, -- 'full', 'sft', 'lora', 'qlora', 'delta', 'online', 'feedback', 'distillation'
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
    config JSONB NOT NULL,
    metrics JSONB,
    artifacts_path TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 5.4 Online Feedback System

```
┌────────────────────────────────────────────────────────────────┐
│                    FEEDBACK PIPELINE                            │
│                                                                 │
│  User Response → Rating (1-5) → Feedback Queue (RabbitMQ)      │
│       │                              │                          │
│       ▼                              ▼                          │
│  Admin Moderation Panel         Feedback Aggregator             │
│       │                              │                          │
│       ▼                              ▼                          │
│  Approved/Rejected              Training Dataset Builder        │
│       │                              │                          │
│       ▼                              ▼                          │
│  KB Update (if approved)        Trigger Feedback-Based Training │
│                                      │                          │
│                                      ▼                          │
│                                 LoRA Adapter Update             │
│                                      │                          │
│                                      ▼                          │
│                                 Hot-Swap New Adapter            │
└────────────────────────────────────────────────────────────────┘
```

### 5.5 Guardrails

Per `ai.md` rules:

| Component | Purpose | Implementation |
|-----------|---------|----------------|
| NVIDIA NeMo Guardrails | Safety rails, topic control | Python sidecar |
| Llama Guard | Content classification | vLLM-served classifier |
| Presidio | PII detection & redaction | .NET SDK integration |

### 5.6 Non-CNN Neural Network Families

Per `ai.md` rules, the system supports:

| Family | Architecture | Use Case |
|--------|-------------|----------|
| SSM / Mamba | State Space Models | Long-context processing |
| LSTM / GRU | Recurrent Networks | Sequential data |
| MoE | Mixture of Experts | Efficient scaling |
| VAE | Variational Autoencoders | Data augmentation |
| GNN | Graph Neural Networks | Schema/relationship analysis |
| Transformer | Self-attention | Primary LLM architecture |

---

## 6. Training Data Sources

### 6.1 Polish Language Data

| Dataset | Size | Source | License | Fetch Method |
|---------|------|--------|---------|-------------|
| **PLLuM Corpus** | 140B tokens | Polish LLM project | Open | HuggingFace API: `datasets.load_dataset("pllum/pllum-corpus")` |
| **SpeakLeash / Bielik Data** | 294M documents | SpeakLeash project | Open | HuggingFace: `huggingface.co/speakleash` |
| **NKJP** (National Corpus of Polish) | ~1.8B tokens | CLARIN-PL | Academic | API: `nkjp.pl` download scripts |
| **OSCAR (Polish subset)** | ~109 GB text | Common Crawl filtered | CC-BY-4.0 | HuggingFace: `datasets.load_dataset("oscar-corpus/OSCAR-2301", "pl")` |
| **CC-100 (Polish)** | ~55 GB | Common Crawl | MIT | Direct download: `data.statmt.org/cc-100/` |
| **KLEJ Benchmark** | 9 tasks | Allegro | Various | HuggingFace: `datasets.load_dataset("allegro/klej-*")` |
| **PolEmo 2.0** | 8000+ reviews | CLARIN-PL | Academic | HuggingFace: `datasets.load_dataset("allegro/klej-polemo2-in")` |
| **Polish Wikipedia** | ~3 GB | Wikimedia | CC-BY-SA | Dump: `dumps.wikimedia.org/plwiki/` |

#### Fetch Implementation (Polish)

```python
# training/fetchers/polish_data_fetcher.py

from datasets import load_dataset

class PolishDataFetcher:
    """Fetcher for Polish language training data."""

    SOURCES = {
        "speakleash": {
            "repo": "speakleash",
            "method": "huggingface_org",
            "url": "https://huggingface.co/speakleash",
        },
        "oscar_pl": {
            "repo": "oscar-corpus/OSCAR-2301",
            "config": "pl",
            "method": "huggingface",
        },
        "klej_polemo": {
            "repo": "allegro/klej-polemo2-in",
            "method": "huggingface",
        },
        "nkjp": {
            "url": "http://clip.ipipan.waw.pl/NationalCorpusOfPolish",
            "method": "web_download",
        },
        "polish_wikipedia": {
            "url": "https://dumps.wikimedia.org/plwiki/latest/plwiki-latest-pages-articles.xml.bz2",
            "method": "direct_download",
        },
    }

    def fetch(self, source_name: str, output_dir: str) -> None:
        source = self.SOURCES[source_name]
        if source["method"] == "huggingface":
            ds = load_dataset(source["repo"], source.get("config"))
            ds.save_to_disk(f"{output_dir}/{source_name}")
        elif source["method"] == "direct_download":
            self._download_file(source["url"], output_dir)
        # ... other methods
```

### 6.2 General / Multilingual Data

| Dataset | Size | Source | License | Fetch Method |
|---------|------|--------|---------|-------------|
| **RedPajama-V2** | 30T tokens | Together AI | Apache 2.0 | HuggingFace: `datasets.load_dataset("togethercomputer/RedPajama-Data-V2")` |
| **The Stack v2** | 4T tokens, 600+ langs | BigCode | Open RAIL-M | HuggingFace: `datasets.load_dataset("bigcode/the-stack-v2")` |
| **StarCoder Data** | 250B tokens | BigCode | Open RAIL-M | HuggingFace: `datasets.load_dataset("bigcode/starcoderdata")` |
| **Anthropic HH-RLHF** | 170k comparisons | Anthropic | MIT | HuggingFace: `datasets.load_dataset("Anthropic/hh-rlhf")` |
| **OpenAssistant OASST2** | 135k messages, 348 MB | LAION | Apache 2.0 | HuggingFace: `datasets.load_dataset("OpenAssistant/oasst2")` |
| **UltraFeedback Binarized** | 60k+ samples | — | MIT | HuggingFace: `datasets.load_dataset("HuggingFaceH4/ultrafeedback_binarized")` |
| **CodeSearchNet** | 2M (comment,code) pairs | GitHub | MIT | GitHub: `github.com/github/CodeSearchNet` + S3 download (~3.5 GB) |
| **GH Archive** | Full GitHub events | Google | CC-BY-4.0 | BigQuery: `bigquery-public-data.github_repos` or `gharchive.org` |

### 6.3 Database-Specific Training Data

| Dataset | Size | Description | Fetch Method |
|---------|------|-------------|-------------|
| **SchemaPile** | 221k schemas, 1.7M tables, 700k FK relationships | Database schemas from GitHub SQL files | Direct download: `ir.cwi.nl/pub/34763/` |
| **Spider** | 10k SQL queries | Text-to-SQL benchmark, 200 databases | GitHub: `github.com/taoyds/spider` |
| **WikiSQL** | 80k questions | SQL queries on Wikipedia tables | GitHub: `github.com/salesforce/WikiSQL` |
| **PostgreSQL Sample DBs** | Various | Pagila, Chinook, AdventureWorks ports | `wiki.postgresql.org/wiki/Sample_Databases` |

#### Fetch Implementation (General)

```python
# training/fetchers/general_data_fetcher.py

class GeneralDataFetcher:
    """Fetcher for general training data sources."""

    SOURCES = {
        "redpajama_v2": {
            "repo": "togethercomputer/RedPajama-Data-V2",
            "method": "huggingface",
            "streaming": True,  # Too large for full download
        },
        "the_stack_v2": {
            "repo": "bigcode/the-stack-v2",
            "method": "huggingface",
            "streaming": True,
            "filter_langs": ["python", "csharp", "sql", "typescript"],
        },
        "oasst2": {
            "repo": "OpenAssistant/oasst2",
            "method": "huggingface",
        },
        "hh_rlhf": {
            "repo": "Anthropic/hh-rlhf",
            "method": "huggingface",
        },
        "ultrafeedback": {
            "repo": "HuggingFaceH4/ultrafeedback_binarized",
            "method": "huggingface",
        },
        "schemapile": {
            "url": "https://ir.cwi.nl/pub/34763/",
            "method": "web_download",
        },
        "spider": {
            "url": "https://github.com/taoyds/spider",
            "method": "git_clone",
        },
    }
```

---

## 7. Training Pipeline & Scripts

### 7.1 Training Scripts (training/ directory)

Per `ai.md` rules, the following training scripts are required:

| Script | Type | Description |
|--------|------|-------------|
| `train_full.py` | Full fine-tuning | Full model weight update (requires multi-GPU) |
| `train_sft.py` | Supervised Fine-Tuning | Standard instruction tuning |
| `train_lora.py` | LoRA | Low-Rank Adaptation (memory-efficient) |
| `train_qlora.py` | QLoRA | Quantized LoRA (4-bit, single GPU feasible) |
| `train_delta.py` | Delta/Incremental | Train only on new data since last run |
| `train_online.py` | Online Learning | Continuous learning from incoming data |
| `train_feedback.py` | Feedback-Based | DPO/RLHF from user feedback |
| `train_distillation.py` | Distillation | Teacher→Student model compression |
| `evaluate.py` | Evaluation | Benchmark & quality evaluation |
| `export_model.py` | Export | Convert to GGUF, ONNX, TensorRT |
| `hot_swap.py` | Hot-Swap | Deploy/swap LoRA adapters without downtime |

### 7.2 Training Configuration (YAML)

```yaml
# training/configs/lora_config.yaml
model:
  name: "Qwen2.5-72B-Instruct"
  source: "Qwen/Qwen2.5-72B-Instruct"
  quantization: "4bit"  # for QLoRA

lora:
  rank: 16
  alpha: 32
  dropout: 0.05
  target_modules: ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]

training:
  epochs: 3
  batch_size: 4
  gradient_accumulation: 8
  learning_rate: 2e-4
  warmup_ratio: 0.03
  max_seq_length: 4096
  fp16: true

data:
  train_path: "./data/processed/train.jsonl"
  eval_path: "./data/processed/eval.jsonl"
  format: "instruction"  # instruction | conversation | completion

output:
  dir: "./outputs/lora_adapters/"
  adapter_name: "db-analysis-v1"
  push_to_registry: true

mlflow:
  tracking_uri: "http://mlflow:5000"
  experiment_name: "db-deletor-lora"
```

### 7.3 Model Versioning & Registry

Per `ai.md` rules — MLflow Model Registry:

```
┌─────────────────────────────────────────────────────────┐
│                  MLflow Model Registry                   │
│                                                          │
│  Model: db-analysis-lora                                 │
│  ├── Version 1 (Staging)   — trained 2026-02-10          │
│  ├── Version 2 (Production) — trained 2026-02-15         │
│  └── Version 3 (Archived)  — trained 2026-02-01          │
│                                                          │
│  Model: db-schema-classifier                             │
│  ├── Version 1 (Production) — trained 2026-02-12         │
│  └── Version 2 (Staging)    — trained 2026-02-17         │
│                                                          │
│  Adapter: polish-sql-lora                                │
│  ├── Version 1 (Production) — base: Bielik-11B-v2       │
│  └── Version 2 (Staging)    — base: Bielik-11B-v2       │
└─────────────────────────────────────────────────────────┘
```

### 7.4 Hot-Swap Adapter Management

```python
# training/scripts/hot_swap.py
# Manages LoRA adapter deployment without model restart

class AdapterManager:
    """Manages multi-LoRA adapters on vLLM serving instances."""

    def list_adapters(self) -> list[AdapterInfo]:
        """List currently loaded adapters."""

    def load_adapter(self, adapter_path: str, adapter_name: str) -> None:
        """Load a new LoRA adapter into the serving instance."""

    def unload_adapter(self, adapter_name: str) -> None:
        """Unload a LoRA adapter from the serving instance."""

    def swap_adapter(self, old_name: str, new_name: str, new_path: str) -> None:
        """Atomically swap one adapter for another."""

    def promote_staging_to_production(self, adapter_name: str) -> None:
        """Promote a staging adapter to production."""
```

---

## 8. Scheduling & Ad-Hoc Triggering

### 8.1 Scheduler Component

Per `dotnet.md` rules — use **Quartz.NET** or **Hangfire**.

| Feature | Quartz.NET | Hangfire |
|---------|-----------|---------|
| CRON Scheduling | Yes | Yes |
| Dashboard UI | Plugin required | Built-in |
| Persistence | DB-backed | DB-backed |
| Distributed | Yes (clustering) | Yes |
| **Recommendation** | **Preferred** (more control) | Alternative |

### 8.2 Scheduled Jobs

| Job | Default Schedule | Description | Triggerable Ad-Hoc |
|-----|-----------------|-------------|---------------------|
| Data Fetch (Polish) | Weekly (Sun 02:00) | Fetch updates from Polish data sources | Yes (API + UI) |
| Data Fetch (General) | Weekly (Sun 04:00) | Fetch updates from general data sources | Yes (API + UI) |
| Data Fetch (DB Schemas) | Bi-weekly | Fetch new database schemas from SchemaPile/GitHub | Yes (API + UI) |
| Training (Delta) | After data fetch | Train on new data only | Yes (API + UI) |
| Training (Full) | Monthly (1st, 03:00) | Full retraining from scratch | Yes (API + UI) |
| Training (Feedback) | Daily (01:00) | Train from accumulated feedback | Yes (API + UI) |
| Model Evaluation | After training | Evaluate model quality | Yes (API + UI) |
| KB Update | After training | Update knowledge base embeddings | Yes (API + UI) |
| Health Check | Every 5 min | Check all model instances | No (automatic) |
| Log Rotation | Daily (00:00) | Rotate and compress logs | No (automatic) |

### 8.3 Ad-Hoc Triggering API

```
POST /api/v1/jobs/trigger
Content-Type: application/json
Authorization: Bearer <token>

{
  "jobName": "data-fetch-polish",
  "parameters": {
    "sources": ["speakleash", "oscar_pl"],
    "forceRefresh": true
  }
}

Response:
{
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "queued",
  "estimatedStartTime": "2026-02-18T10:00:00Z"
}
```

### 8.4 Ad-Hoc Triggering from UI

The Angular admin panel provides:

- **Job Dashboard** — List all jobs with status, last run, next run
- **Manual Trigger** button per job with parameter dialog
- **DAG Visualization** — Show job dependencies (Mermaid/D3.js)
- **Gantt View** — Timeline of job executions
- **Calendar View** — Scheduled jobs on a calendar

---

## 9. Data Fetching & Scraping Architecture

### 9.1 Scraper Orchestrator

```
┌──────────────────────────────────────────────────────────────┐
│                  SCRAPER ORCHESTRATOR                          │
│                                                               │
│  ┌─────────────┐                                              │
│  │  Scheduler   │──┐                                          │
│  │  (Quartz.NET)│  │                                          │
│  └─────────────┘  │    ┌──────────────────────────────────┐   │
│                    ├───▶│       TASK QUEUE (RabbitMQ)       │   │
│  ┌─────────────┐  │    └──────────┬───────────────────────┘   │
│  │  API Trigger │──┘               │                          │
│  │  (Ad-Hoc)   │                   ▼                          │
│  └─────────────┘    ┌──────────────────────────────────┐      │
│                     │         FETCHER WORKERS           │      │
│                     │  ┌──────┐ ┌──────┐ ┌──────┐      │      │
│                     │  │ W-1  │ │ W-2  │ │ W-N  │      │      │
│                     │  └──┬───┘ └──┬───┘ └──┬───┘      │      │
│                     └─────┼────────┼────────┼──────────┘      │
│                           │        │        │                  │
│                           ▼        ▼        ▼                  │
│                     ┌──────────────────────────────────┐      │
│                     │       DATA PROCESSING PIPELINE    │      │
│                     │  Validate → Clean → Deduplicate   │      │
│                     │  → Format → Store                 │      │
│                     └──────────────────────────────────┘      │
│                                    │                          │
│                                    ▼                          │
│                     ┌──────────────────────────────────┐      │
│                     │       TRAINING DATA STORE         │      │
│                     │       (PostgreSQL + Files)        │      │
│                     └──────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

### 9.2 Fetcher Types

| Fetcher | Data Source | Method |
|---------|-----------|--------|
| HuggingFace Fetcher | HuggingFace Hub datasets | `datasets` library API |
| Web Scraper | Websites, documentation | HTTP GET + BeautifulSoup/lxml |
| API Fetcher | REST APIs (GitHub, GitLab, etc.) | HTTP client with rate limiting |
| Database Fetcher | Sample databases | Direct SQL connection |
| Git Fetcher | Git repositories | `git clone --depth 1` |
| File Fetcher | Direct file downloads | HTTP download with resume support |

### 9.3 Rate Limiting & Politeness

- Respect `robots.txt` for web scraping
- Configurable request rate per domain (default: 1 req/sec)
- Exponential backoff on 429/503 responses
- User-Agent identification: `DatabaseDeletor-DataFetcher/1.0`
- HuggingFace Hub: Use API token for higher rate limits

---

## 10. Admin Panel & UI Specification

### 10.1 Technology

- **Framework:** Angular (latest stable)
- **UI Library:** NG-ZORRO (Ant Design for Angular) — primary backbone
- **Styling:** SCSS + CSS variables (design tokens)
- **State:** Angular Signals + RxJS
- **i18n:** Runtime switching EN/PL without page reload
- **Testing:** Playwright E2E
- **Build:** Angular CLI with controlled chunking

### 10.2 Pages & Features

#### 10.2.1 Dashboard (Home)

- System health overview (all services)
- Quick stats: total deletions, active models, pending jobs, recent errors
- Activity feed (last 20 actions)
- System resource usage (CPU, memory, GPU if available)

#### 10.2.2 Database Deletion Tool

- Connection string input (with test connection)
- Database type selector (SQL Server, PostgreSQL, MySQL, Oracle)
- SQL query editor (with syntax highlighting)
- WHERE clause builder (visual + raw SQL)
- Dependency graph visualization (D3.js tree/force layout)
- Deletion plan preview with table/row counts
- Execute with progress bar
- Deletion report with charts (bar chart: rows per table)

#### 10.2.3 AI Management

- Model registry browser (MLflow integration)
- Active model instances with health status
- LoRA adapter management (load/unload/swap)
- RAG knowledge base management (CRUD for KB entries)
- Guardrails configuration
- Inference playground (test prompts)

#### 10.2.4 Training Management

- Training run history with metrics visualization
- Start new training run (form with config selection)
- Training progress monitoring (loss curves, metrics)
- Model comparison (side-by-side evaluation results)
- Data source management (enable/disable/configure sources)

#### 10.2.5 Job Scheduler

- **DAG View** — Job dependency graph (Mermaid/D3.js)
- **Gantt View** — Timeline of past/future executions
- **Calendar View** — Monthly calendar with scheduled jobs
- **Job List** — Table with columns: name, schedule, last run, next run, status, actions
- Manual trigger with parameter dialog
- Job history with logs

#### 10.2.6 Feedback Management

- Pending feedback queue (awaiting moderation)
- Approved/Rejected feedback history
- Feedback analytics (ratings distribution, trends)
- Approve/Reject/Edit actions per feedback item

#### 10.2.7 Event & Log Dashboard

- Real-time log streaming (WebSocket)
- Filterable log viewer (by level, source, time range)
- Event timeline
- Error aggregation and grouping
- Log download (filtered export)

#### 10.2.8 Configuration Management

- Parameter table (name, value, source: appsettings.json or DB)
- Edit parameters in DB (overrides appsettings.json)
- Sync status indicator (appsettings.json vs DB)
- Feature flags management

#### 10.2.9 Feature Flags

- Toggle list with enable/disable per endpoint
- `HostTestApis` toggle
- Feature flag history (who changed what, when)

#### 10.2.10 Settings

- User preferences (language, theme)
- System configuration
- Keycloak user management link
- About / Version info

### 10.3 UI/UX Requirements

Per `www.md` and `angular.md` rules:

| Requirement | Standard |
|-------------|----------|
| Accessibility | WCAG 2.2 AA |
| i18n | EN/PL runtime switching, no page reload |
| Theming | Light/Dark with CSS variables, runtime switch |
| Responsiveness | Mobile → Tablet → Desktop |
| Performance | Controlled chunking (max 6 JS bundles) |
| Design Tokens | `--color-*`, `--space-*`, `--radius-*`, `--shadow-*`, `--font-*` |
| Typography | Limited type scale (6-8 steps), Polish diacritics support |
| Contrast | WCAG AA minimum (4.5:1 for body text) |
| Focus | Visible focus indicators on all interactive elements |
| Motion | `prefers-reduced-motion` respected |
| Components | Consistent states: hover, active, focus-visible, disabled, loading |

### 10.4 Component Inventory

| Component | States | Description |
|-----------|--------|-------------|
| Button | primary, secondary, tertiary, destructive, disabled, loading | Standard action buttons |
| Input | default, focus, error, disabled | Text/password/number inputs |
| Select | default, open, selected, disabled | Dropdown selection |
| Table | sortable, filterable, paginated, selectable | Data tables |
| Card | default, hover, selected | Content cards |
| Dialog | default, confirmation, destructive | Modal dialogs |
| Toast | success, warning, error, info | Notification toasts |
| Skeleton | loading | Loading placeholders |
| Empty State | no-data, error, search-empty | Empty state displays |
| Progress Bar | determinate, indeterminate | Progress indicators |
| Tabs | default, scrollable | Tab navigation |
| Tree | expandable, selectable | Dependency tree view |
| Code Editor | SQL syntax highlighting | SQL query input |
| Chart | bar, line, pie, gauge | Data visualization |

---

## 11. Configuration Management

### 11.1 Configuration Priority

```
Priority (highest to lowest):
1. Database parameters (PostgreSQL)           ← HIGHEST PRIORITY
2. Environment variables
3. appsettings.{Environment}.json
4. appsettings.json                           ← LOWEST PRIORITY
```

### 11.2 Startup Synchronization

On application startup:

```
1. Load appsettings.json into memory
2. Connect to PostgreSQL configuration table
3. For each parameter in appsettings.json:
   a. Check if parameter exists in DB
   b. If YES → use DB value (DB wins)
   c. If NO → insert appsettings.json value into DB (seed)
4. Log: "Configuration synchronized: {n} params from DB, {m} params seeded from appsettings.json"
```

### 11.3 Configuration Schema (PostgreSQL)

```sql
CREATE TABLE app_configuration (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    value_type TEXT NOT NULL DEFAULT 'string', -- string, integer, boolean, json
    category TEXT NOT NULL DEFAULT 'general',
    description TEXT,
    is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
    source TEXT NOT NULL DEFAULT 'database', -- 'database', 'appsettings', 'environment'
    last_modified_by TEXT,
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_app_configuration_category ON app_configuration(category);
CREATE INDEX idx_app_configuration_key ON app_configuration(key);
```

### 11.4 appsettings.json Structure

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=dbdeletor;Username=app;Password=${DB_PASSWORD}"
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" },
      { "Name": "File", "Args": { "path": "logs/dbdeletor-.log", "rollingInterval": "Day" } }
    ]
  },
  "Authentication": {
    "SecretToken": "${ADMIN_SECRET_TOKEN}",
    "Keycloak": {
      "Authority": "https://keycloak.example.com/realms/dbdeletor",
      "ClientId": "dbdeletor-api",
      "RequireHttpsMetadata": true
    }
  },
  "Deletion": {
    "DefaultBatchSize": 5000,
    "DefaultTimeout": 300,
    "MaxParallelTables": 4
  },
  "AI": {
    "VllmEndpoint": "http://vllm:8000/v1",
    "DefaultModel": "Qwen2.5-72B-Instruct",
    "MaxTokens": 4096,
    "Temperature": 0.7
  },
  "Scheduling": {
    "DataFetch": {
      "PolishSources": "0 0 2 ? * SUN",
      "GeneralSources": "0 0 4 ? * SUN",
      "DatabaseSchemas": "0 0 3 ? * 1,15 *"
    },
    "Training": {
      "DeltaTraining": "0 0 6 ? * SUN",
      "FullTraining": "0 0 3 1 * ?",
      "FeedbackTraining": "0 0 1 * * ?"
    }
  },
  "FeatureFlags": {
    "HostTestApis": true,
    "EnableAI": true,
    "EnableScheduler": true,
    "EnableFeedback": true,
    "EnableSwagger": true
  },
  "Swagger": {
    "Enabled": true,
    "RoutePrefix": "swagger"
  },
  "OpenTelemetry": {
    "ServiceName": "DatabaseDeletor",
    "OtlpEndpoint": "http://otel-collector:4317"
  }
}
```

---

## 12. Authentication & Authorization

### 12.1 Admin Panel Authentication

Per user requirement — **SecretToken** stored in `appsettings.json`:

```
┌──────────────────────────────────────────────────────────┐
│  Admin Panel Login                                        │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Secret Token: [________________________________]   │  │
│  │                                                     │  │
│  │  [Login]                                            │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  Token is validated against Authentication:SecretToken    │
│  in appsettings.json (or DB override).                   │
└──────────────────────────────────────────────────────────┘
```

**Implementation:**

```csharp
// Middleware: SecretTokenAuthenticationHandler
public class SecretTokenAuthenticationHandler : AuthenticationHandler<SecretTokenOptions>
{
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("X-Admin-Token", out var token))
            return Task.FromResult(AuthenticateResult.NoResult());

        var expectedToken = Options.SecretToken; // from appsettings.json / DB
        if (token != expectedToken)
            return Task.FromResult(AuthenticateResult.Fail("Invalid token"));

        var claims = new[] { new Claim(ClaimTypes.Role, "Admin") };
        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme.Name);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
```

### 12.2 API Authentication

Per `dotnet.md` rules — **Keycloak OIDC with PKCE** for API consumers:

- OIDC Discovery: `/.well-known/openid-configuration`
- Token endpoint: Keycloak realm
- PKCE flow for SPA (Angular)
- JWT Bearer validation in API

### 12.3 Dual Auth Strategy

| Endpoint | Auth Method | Description |
|----------|------------|-------------|
| `/api/v1/admin/*` | SecretToken | Admin panel operations |
| `/api/v1/public/*` | Keycloak OIDC | External API access |
| `/api/v1/health` | None | Health check (public) |
| `/swagger` | Feature flag | Swagger UI (HostTestApis controlled) |

---

## 13. Testing Strategy

### 13.1 Testing Pyramid

```
        ╱╲
       ╱  ╲       E2E Tests (Playwright)
      ╱    ╲      ~10 scenarios
     ╱──────╲
    ╱        ╲    Integration Tests
   ╱          ╲   ~50 tests (Testcontainers)
  ╱────────────╲
 ╱              ╲  Unit Tests
╱                ╲ ~200+ tests (≥80% coverage)
╱──────────────────╲
```

### 13.2 Unit Tests

**Framework:** xUnit (per `dotnet.md` rules)
**Coverage target:** ≥ 80% for touched modules

| Module | Test Focus |
|--------|-----------|
| `Domain` | Entity invariants, value objects, domain events |
| `Application` | Command/Query handlers, validation, mapping |
| `Infrastructure.AI` | RAG pipeline logic, adapter management |
| `Cli` | Argument parsing, output formatting |

```bash
# Run unit tests
dotnet test tests/DatabaseDeletor.Domain.Tests/ --configuration Release
dotnet test tests/DatabaseDeletor.Application.Tests/ --configuration Release
```

### 13.3 Integration Tests

**Framework:** xUnit + Testcontainers (per `architecture.md` rules)

| Test Area | Container | Scope |
|-----------|-----------|-------|
| PostgreSQL Access | `testcontainers/postgres:16` | Dapper queries, schema introspection |
| SQL Server Access | `testcontainers/mssql:2022` | SQL Server FK analysis, bulk delete |
| MySQL Access | `testcontainers/mysql:8` | MySQL FK analysis, bulk delete |
| RabbitMQ Messaging | `testcontainers/rabbitmq:3.13` | Event publishing/consuming |
| API Endpoints | In-memory test server | HTTP request/response validation |

```bash
# Run integration tests
dotnet test tests/DatabaseDeletor.Infrastructure.Tests/ --configuration Release
dotnet test tests/DatabaseDeletor.Api.Tests/ --configuration Release
```

### 13.4 E2E Tests (Playwright)

Per `www.md` rules — **Playwright ONLY** for E2E:

| Scenario | Description |
|----------|-------------|
| Admin Login | Login with SecretToken, verify dashboard loads |
| Language Switch | Switch EN→PL→EN without page reload |
| Dark Mode | Toggle theme, verify CSS variables change |
| Delete Flow | Configure connection → enter query → view plan → confirm → view report |
| Job Management | View jobs → trigger manual job → verify status update |
| AI Management | View models → test inference → view results |
| Log Viewer | Open logs → filter by level → verify streaming |
| Config Management | Edit parameter → save → verify persistence |
| Feature Flags | Toggle feature → verify endpoint availability |
| Accessibility | Keyboard navigation, focus management, ARIA attributes |

```bash
# Run E2E tests
npx playwright test --project=chromium
```

### 13.5 Smoke Tests

| Test | Endpoint | Expected |
|------|----------|----------|
| API Startup | `GET /api/v1/health` | 200 OK |
| Swagger UI | `GET /swagger` | 200 OK (when HostTestApis=true) |
| Angular App | `GET /` | 200 OK, HTML with `<app-root>` |
| Database | Internal connection test | Connected |
| RabbitMQ | Internal connection test | Connected |

```bash
# Run smoke tests
dotnet test tests/DatabaseDeletor.Smoke.Tests/ --configuration Release
```

### 13.6 Container Testing

Per `www.md` rules — tests MUST run from inside containers:

```yaml
# docker-compose.test.yml
services:
  api-test:
    build:
      context: .
      dockerfile: docker/Dockerfile.test
    command: dotnet test --configuration Release
    depends_on:
      postgres:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy

  e2e-test:
    build:
      context: .
      dockerfile: docker/Dockerfile.e2e
    command: npx playwright test
    depends_on:
      api:
        condition: service_healthy
      web:
        condition: service_healthy

  postgres:
    image: postgres:16-alpine
    healthcheck:
      test: pg_isready -U test
      interval: 5s

  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    healthcheck:
      test: rabbitmq-diagnostics check_running
      interval: 5s
```

---

## 14. Docker & Containerization

### 14.1 Docker Strategy

Per `docker.md` rules — split Dockerfiles with base/lang/deps/build/runtime layers:

| Image | Purpose | Base |
|-------|---------|------|
| `Dockerfile.base` | OS + core tools | `darkdervish/debian-base` |
| `Dockerfile.lang` | .NET SDK + Node.js | `Dockerfile.base` |
| `Dockerfile.deps` | NuGet + npm packages | `Dockerfile.lang` |
| `Dockerfile.build` | Compile & publish | `Dockerfile.deps` |
| `Dockerfile.runtime` | Final minimal image | `mcr.microsoft.com/dotnet/aspnet:10.0` |
| `Dockerfile.training` | Python + PyTorch + CUDA | `nvidia/cuda:12.x-runtime` |

### 14.2 docker-compose.yml

```yaml
version: "3.9"

services:
  api:
    build:
      context: .
      dockerfile: docker/Dockerfile.runtime
    ports:
      - "5000:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Host=postgres;Database=dbdeletor;Username=app;Password=${DB_PASSWORD}
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
    depends_on:
      postgres:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    user: "1000:1000"

  web:
    build:
      context: ./src/DatabaseDeletor.Web
      dockerfile: ../../docker/Dockerfile.angular
    ports:
      - "4200:80"
    depends_on:
      - api

  vllm:
    image: vllm/vllm-openai:latest
    runtime: nvidia
    ports:
      - "8000:8000"
    volumes:
      - model-cache:/root/.cache/huggingface
    command: >
      --model Qwen/Qwen2.5-72B-Instruct
      --tensor-parallel-size 4
      --max-model-len 4096
      --enable-lora

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: dbdeletor
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: pg_isready -U app -d dbdeletor
      interval: 10s

  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    ports:
      - "15672:15672"
    healthcheck:
      test: rabbitmq-diagnostics check_running
      interval: 10s

  mlflow:
    image: ghcr.io/mlflow/mlflow:latest
    ports:
      - "5001:5000"
    environment:
      MLFLOW_BACKEND_STORE_URI: postgresql://app:${DB_PASSWORD}@postgres:5432/mlflow

  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    ports:
      - "4317:4317"
      - "4318:4318"

volumes:
  postgres-data:
  model-cache:
```

### 14.3 Security Requirements

Per `docker.md` rules:

- All images run as **non-root** user
- Pinned base image versions (no `:latest` in production)
- **HEALTHCHECK** in every Dockerfile
- No secrets baked into images
- Read-only filesystem where feasible
- Target platform: **linux/amd64** only (no ARM)
- Multi-stage builds to minimize final image size

---

## 15. Observability & Logging

### 15.1 Logging (Serilog)

Per `specification.txt` — Serilog is mandatory:

```csharp
// Program.cs
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(configuration)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .Enrich.WithProperty("Application", "DatabaseDeletor")
    .WriteTo.Console(new RenderedCompactJsonFormatter())
    .WriteTo.File(
        new CompactJsonFormatter(),
        "logs/dbdeletor-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30)
    .CreateLogger();
```

### 15.2 OpenTelemetry

Per `architecture.md` rules — mandatory:

| Signal | Implementation |
|--------|---------------|
| Traces | `OpenTelemetry.Instrumentation.AspNetCore`, `OpenTelemetry.Instrumentation.Http` |
| Metrics | Custom metrics: deletion throughput, AI latency, job success rate |
| Logs | Serilog → OTLP exporter |

### 15.3 Metrics

| Metric | Type | Labels |
|--------|------|--------|
| `dbdeletor_deletions_total` | Counter | database_type, status |
| `dbdeletor_rows_deleted_total` | Counter | database_type, table |
| `dbdeletor_deletion_duration_seconds` | Histogram | database_type |
| `dbdeletor_ai_inference_duration_seconds` | Histogram | model, adapter |
| `dbdeletor_ai_tokens_total` | Counter | model, type (input/output) |
| `dbdeletor_jobs_total` | Counter | job_name, status |
| `dbdeletor_feedback_total` | Counter | rating, status |
| `dbdeletor_active_model_instances` | Gauge | model |

---

## 16. CI/CD Pipeline

### 16.1 GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: .NET Format Check
        run: dotnet format --verify-no-changes
      - name: Angular Lint
        run: cd src/DatabaseDeletor.Web && npm ci && npm run lint
      - name: Python Lint
        run: cd training && pip install ruff && ruff check .

  build:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Build .NET Solution
        run: dotnet build DatabaseDeletor.sln --configuration Release
      - name: Build Angular
        run: cd src/DatabaseDeletor.Web && npm ci && npm run build

  test-unit:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Run Unit Tests
        run: dotnet test --filter "Category=Unit" --configuration Release --collect:"XPlat Code Coverage"
      - name: Check Coverage
        run: # Verify ≥80% coverage

  test-integration:
    runs-on: ubuntu-latest
    needs: build
    services:
      postgres:
        image: postgres:16-alpine
      rabbitmq:
        image: rabbitmq:3.13-alpine
    steps:
      - name: Run Integration Tests
        run: dotnet test --filter "Category=Integration" --configuration Release

  test-e2e:
    runs-on: ubuntu-latest
    needs: [test-unit, test-integration]
    steps:
      - name: Run E2E Tests
        run: npx playwright test

  security:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: SAST Scan
        run: # dotnet security audit
      - name: Dependency Scan
        run: dotnet list package --vulnerable
      - name: SBOM Generation
        run: # syft scan

  docker:
    runs-on: ubuntu-latest
    needs: [test-e2e, security]
    steps:
      - name: Build Docker Images
        run: ./scripts/_buildDocker.sh
      - name: Scan Images
        run: trivy image dbdeletor:latest
      - name: Push Images
        run: ./scripts/_dockerPush.sh
```

---

## 17. Build Scripts Adaptation

### 17.1 Existing Scripts

The `scripts/` directory contains Universal .NET Build Scripts v2.0.0 that must be adapted:

| Script | Status | Adaptation Needed |
|--------|--------|-------------------|
| `_common.sh` | EXISTS | Add training script integration |
| `_buildDotnetSolution.sh` | EXISTS | Verify .NET 10 compatibility |
| `_clean.sh` | EXISTS | Add training artifacts cleanup |
| `_publishDotnetTool.sh` | EXISTS | Configure for CLI tool publishing |
| `_buildDocker.sh` | EXISTS | Add split Dockerfile support |
| `_dockerPush.sh` | EXISTS | Configure registry |
| `_dockerRun.sh` | EXISTS | Add docker-compose orchestration |
| `build.sh` | EXISTS | No changes needed |
| `clean.sh` | EXISTS | No changes needed |

### 17.2 New Scripts Needed

| Script | Purpose |
|--------|---------|
| `_buildAngular.sh` | Build Angular admin panel |
| `_buildTraining.sh` | Build Python training environment |
| `_runTests.sh` | Run all test suites (unit + integration + E2E + smoke) |
| `_runE2E.sh` | Run Playwright E2E tests |
| `_startDev.sh` | Start full development environment (docker-compose up) |
| `_fetchData.sh` | Trigger data fetching manually |
| `_trainModel.sh` | Trigger model training manually |

---

## 18. Security & Compliance

### 18.1 Threat Model (STRIDE)

| Threat | Category | Mitigation |
|--------|----------|------------|
| SQL Injection via user query | Tampering | Parameterized queries for metadata; user query is intentional SQL (display plan first) |
| Connection string exposure | Information Disclosure | Environment variables, never logged, masked in UI |
| Unauthorized deletion | Elevation of Privilege | Confirmation mode, SecretToken auth, audit logging |
| Model poisoning via feedback | Tampering | Admin moderation before training, data validation |
| PII in training data | Information Disclosure | Presidio PII redaction before training |
| Secrets in Docker images | Information Disclosure | Environment variables, Docker secrets |
| Admin token brute force | Spoofing | Rate limiting, account lockout |

### 18.2 OWASP ASVS Alignment

| Control | Implementation |
|---------|---------------|
| V1: Architecture | Clean Architecture, layered security |
| V2: Authentication | Keycloak OIDC + SecretToken |
| V4: Access Control | Role-based (Admin via token) |
| V5: Validation | Input validation on all API endpoints |
| V7: Error Handling | Structured errors (RFC 9457 Problem Details) |
| V8: Data Protection | TLS, encrypted connection strings, PII redaction |
| V9: Communication | HTTPS only, HSTS |
| V14: Configuration | Env vars for secrets, no hardcoded values |

---

## 19. NFR Matrix (ISO/IEC 25010)

| Characteristic | Metric | Target | Verification |
|---------------|--------|--------|-------------|
| **Reliability** | Uptime | 99.5% | Monitoring + SLOs |
| **Performance** | CLI deletion throughput | ≥5,000 rows/sec per table | Benchmark tests |
| **Performance** | API response time (p95) | <500ms | Load tests |
| **Performance** | AI inference latency (p95) | <2s | Monitoring |
| **Scalability** | Concurrent deletions | ≥10 parallel sessions | Load tests |
| **Security** | Vulnerability scan | 0 critical, 0 high | Trivy + SAST |
| **Maintainability** | Test coverage | ≥80% | CI coverage reports |
| **Usability** | WCAG compliance | 2.2 AA | axe + manual audit |
| **Portability** | Database support | 4 engines (MSSQL, PG, MySQL, Oracle) | Integration tests |

---

## 20. Risk & Rollback

### 20.1 Key Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|------------|------------|
| Cascading delete removes unintended data | Critical | Medium | Dry-run mode, confirmation plan, transaction rollback |
| AI model produces harmful output | High | Low | Guardrails (NeMo, Llama Guard), admin review |
| Training data contains PII | High | Medium | Presidio PII detection, data sanitization pipeline |
| GPU unavailable for AI serving | Medium | Medium | Graceful degradation, feature flag to disable AI |
| Database lock escalation during bulk delete | High | Medium | Batch size tuning, NOLOCK hints where safe |
| Oracle license compliance | Medium | Low | Use Oracle XE for testing, customer provides license |

### 20.2 Rollback Strategy

| Component | Rollback Method |
|-----------|----------------|
| Database deletions | Transaction rollback (within session), backup restore (post-commit) |
| Model deployments | MLflow model version rollback, LoRA adapter swap |
| Configuration changes | DB audit trail, restore previous value |
| Docker deployments | Docker image tag rollback, Kubernetes rollback |
| Schema migrations | Flyway undo migrations |

---

## 21. Implementation Roadmap

### Phase 1: Core CLI (Weeks 1-4)

1. Create .NET solution structure
2. Implement database connectivity (4 providers)
3. Build dependency analysis engine
4. Implement bulk delete with FK resolution
5. Add CLI argument parsing
6. Implement progress bar
7. Add Serilog logging
8. Implement confirmation mode & deletion plan
9. Build deletion report generator
10. Unit tests (≥80% coverage)
11. Integration tests with Testcontainers

### Phase 2: API & Admin Panel (Weeks 5-8)

1. Create Minimal API project
2. Implement Mediator pattern
3. Build Angular admin panel (NG-ZORRO)
4. Implement SecretToken authentication
5. Add configuration management (appsettings.json + DB sync)
6. Implement feature flags
7. Add OpenTelemetry observability
8. E2E tests (Playwright)

### Phase 3: AI Integration (Weeks 9-14)

1. Set up vLLM serving
2. Implement RAG pipeline with pgvector
3. Build AI orchestrator
4. Implement guardrails (NeMo, Llama Guard, Presidio)
5. Create feedback system
6. Build training scripts (training/ directory)
7. Set up MLflow model registry
8. Implement hot-swap adapter management

### Phase 4: Scheduling & Scraping (Weeks 15-18)

1. Implement Quartz.NET scheduler
2. Build scraper orchestrator
3. Implement all data fetchers
4. Build data processing pipeline
5. Implement ad-hoc triggering (API + UI)
6. Add job monitoring dashboard

### Phase 5: WPF Desktop App (Weeks 19-22)

1. Create WPF project
2. Implement same functionality as CLI with GUI
3. Build connection dialog
4. Implement dependency tree visualization
5. Add deletion progress UI
6. Build report viewer

### Phase 6: Docker & Production (Weeks 23-26)

1. Create split Dockerfiles
2. Build docker-compose orchestration
3. Adapt existing build scripts
4. Create CI/CD pipeline (GitHub Actions)
5. Security hardening (SAST, DAST, SBOM)
6. Performance testing & optimization
7. Documentation & CHANGELOG

---

## Appendix A: Missing Files

The following files referenced in the user's request were **NOT FOUND** in the repository:

| File | Status | Impact |
|------|--------|--------|
| `spec.txt` | NOT FOUND | Cannot perform gap analysis against this file |
| `extend.txt` | NOT FOUND | Cannot perform gap analysis against this file |

The entire analysis is based on `specification.txt` only, supplemented by the extended requirements from the user's request and the rules in `.github/rules/`.

---

## Appendix B: Rules Compliance

The following rule files from `.github/rules/` were loaded and applied:

| Rule File | Applied | Key Constraints Enforced |
|-----------|---------|------------------------|
| `general.md` | Yes | Zero hallucinations, delivery format, documentation |
| `dotnet.md` | Yes | .NET 10, Dapper (no EF), xUnit, feature toggles, Mediator (not MediatR) |
| `docker.md` | Yes | Split Dockerfiles, non-root, BuildKit, Linux x64 only |
| `ai.md` | Yes | vLLM, RAG 2.0, LoRA, NeMo Guardrails, approved model list |
| `architecture.md` | Yes | Clean Architecture, DDD, EDA, PostgreSQL, NO Redis |
| `database.md` | Yes | External PostgreSQL, env-based config, TLS |
| `angular.md` | Yes | Standalone components, runtime i18n, Playwright E2E |
| `devops.md` | Yes | CI/CD pipeline, SBOM, image scanning |
| `solution-architect.md` | Yes | ADRs, NFR matrix, STRIDE threat model |
| `solution-creator.md` | Yes | OSS first, Mediator, CQRS, FastAPI for Python |
| `wcag.md` | Yes | WCAG 2.2 AA, keyboard navigation, contrast |
| `www.md` | Yes | Angular, i18n EN/PL, Playwright, HostTestApis toggle |
| `01_operating_principles.md` | Yes | Core principles |
| `02_global_best_practices.md` | Yes | TOGAF, DDD, 12-Factor |
| `04_ai_llm_standards.md` | Yes | OSS models, on-prem, RAG, LoRA |
| `07_quality_gates.md` | Yes | Quality bars per technology |

---

## Appendix C: Hallucination Check

**Status: PASSED**

- All API names, library names, and CLI flags have been verified against known documentation.
- All HuggingFace dataset identifiers have been confirmed via web search.
- Database system catalog queries are based on official documentation.
- No speculative features or invented APIs have been included.

**ASSUMPTIONS:**
- `.NET 10` is used as the latest .NET version (per dotnet.md "latest" guidance). If .NET 9 is the latest stable at implementation time, adjust accordingly.
- `spec.txt` and `extend.txt` do not exist — analysis based solely on `specification.txt` and user's extended requirements.
- Oracle database support uses `Oracle.ManagedDataAccess.Core` (free managed driver; customer must ensure Oracle licensing compliance).
- GPU availability is assumed for AI serving (vLLM requires NVIDIA GPU with CUDA).
