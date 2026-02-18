# DatabaseDeletor

A .NET 10 command-line tool and API for mass database deletion with automatic dependency analysis and foreign key resolution. Supports SQL Server, PostgreSQL, MySQL, and Oracle.

## Features

- **Automatic dependency analysis** — Discovers foreign key relationships and builds a dependency graph using topological sort
- **Deletion plan generation** — Creates an ordered deletion plan respecting referential integrity
- **Bulk delete execution** — Provider-specific optimized bulk deletion with configurable batch sizes
- **4 database providers** — SQL Server, PostgreSQL, MySQL, Oracle with native ADO.NET drivers
- **SQL parsing** — Extracts target table and schema from `DELETE FROM` or `SELECT FROM` statements
- **Interactive confirmation** — Displays deletion plan with affected tables, row counts, and asks for confirmation before executing
- **Progress tracking** — Real-time progress bars via Spectre.Console during deletion operations
- **Structured logging** — Serilog with file and console sinks, JSON formatting
- **REST API** — Minimal API endpoint with Swagger/OpenAPI documentation
- **Clean Architecture** — Domain-driven design with CQRS command/handler pattern

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Presentation                       │
│  ┌─────────────────┐     ┌─────────────────────────┐ │
│  │  CLI (Spectre +  │     │  API (Minimal API +     │ │
│  │  System.Command-  │     │  Swagger + Serilog)     │ │
│  │  Line)           │     │                         │ │
│  └────────┬─────────┘     └────────┬────────────────┘ │
├───────────┼────────────────────────┼──────────────────┤
│           │         Application    │                  │
│  ┌────────▼────────────────────────▼────────────────┐ │
│  │  Commands / Handlers / Custom Mediator / SqlParser│ │
│  └──────────────────────┬───────────────────────────┘ │
├─────────────────────────┼────────────────────────────┤
│                         │  Domain                     │
│  ┌──────────────────────▼───────────────────────────┐ │
│  │  Entities / Interfaces / Enums / Exceptions       │ │
│  └──────────────────────┬───────────────────────────┘ │
├─────────────────────────┼────────────────────────────┤
│                         │  Infrastructure             │
│  ┌──────────────────────▼───────────────────────────┐ │
│  │  DB Providers / Schema Introspectors /            │ │
│  │  Bulk Delete Executors / Dependency Analyzer      │ │
│  │  (SQL Server | PostgreSQL | MySQL | Oracle)       │ │
│  └──────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### Projects

| Project | Type | Description |
|---------|------|-------------|
| `DatabaseDeletor.Domain` | Class Library | Entities, interfaces, enums, exceptions, domain events |
| `DatabaseDeletor.Application` | Class Library | CQRS commands/handlers, custom Mediator, SQL parser |
| `DatabaseDeletor.Infrastructure` | Class Library | 4 DB providers, schema introspection, bulk deletion, Dapper |
| `DatabaseDeletor.Infrastructure.AI` | Class Library | AI/ML subsystem (Phase 2 placeholder) |
| `DatabaseDeletor.Cli` | Console App | CLI entry point with System.CommandLine + Spectre.Console |
| `DatabaseDeletor.Api` | Web App | Minimal API with Swagger, health check endpoint |
| `DatabaseDeletor.Domain.Tests` | xUnit Tests | 54 unit tests for domain entities and value objects |
| `DatabaseDeletor.Application.Tests` | xUnit Tests | 36 unit tests for handlers, mediator, DI, SQL parser |
| `DatabaseDeletor.Infrastructure.Tests` | xUnit Tests | 64 unit tests for providers, introspectors, executors, DI |
| `DatabaseDeletor.Cli.Tests` | xUnit Tests | CLI-specific tests |
| `DatabaseDeletor.Api.Tests` | xUnit Tests | API endpoint tests |

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) (10.0.100 or later)
- One or more of the supported databases for testing:
  - SQL Server 2019+
  - PostgreSQL 14+
  - MySQL 8.0+
  - Oracle 19c+
- Docker (optional, for containerized deployment)

## Getting Started

### Build

```bash
# Restore and build all projects
dotnet build

# Build in Release configuration
dotnet build -c Release
```

### Run Tests

```bash
# Run all tests
dotnet test

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"

# Run specific test project
dotnet test tests/DatabaseDeletor.Domain.Tests
```

### Run the CLI

```bash
# Show help
dotnet run --project src/DatabaseDeletor.Cli -- --help

# Delete records from a SQL Server database
dotnet run --project src/DatabaseDeletor.Cli -- \
  --connection-string "Server=localhost;Database=MyDb;User Id=sa;Password=YourPass;TrustServerCertificate=True" \
  --sql "DELETE FROM dbo.Orders WHERE OrderDate < '2020-01-01'"

# Delete with auto-confirm and custom batch size
dotnet run --project src/DatabaseDeletor.Cli -- \
  -c "Host=localhost;Database=mydb;Username=postgres;Password=secret" \
  -s "DELETE FROM public.logs WHERE created_at < '2024-01-01'" \
  --no-confirm \
  --batch-size 50000

# Enable verbose logging
dotnet run --project src/DatabaseDeletor.Cli -- \
  -c "Server=localhost;Database=testdb;User Id=sa;Password=pass;TrustServerCertificate=True" \
  -s "DELETE FROM schema1.audit_trail" \
  --verbose
```

### Run the API

```bash
# Start the API server
dotnet run --project src/DatabaseDeletor.Api

# Health check
curl http://localhost:5000/health

# Swagger UI (development mode)
# Navigate to http://localhost:5000/swagger
```

## CLI Options

| Option | Short | Required | Default | Description |
|--------|-------|----------|---------|-------------|
| `--connection-string` | `-c` | Yes | — | Full database connection string |
| `--sql` | `-s` | Yes | — | SQL query targeting the table (`DELETE FROM` or `SELECT FROM`) |
| `--no-confirm` | `-y` | No | `false` | Skip confirmation prompt |
| `--batch-size` | `-b` | No | `10000` | Batch size for bulk delete operations |
| `--verbose` | `-v` | No | `false` | Enable verbose console logging |

## How It Works

1. **Parse SQL** — Extracts the target table name and schema from the provided SQL statement
2. **Detect provider** — Auto-detects the database provider (SQL Server, PostgreSQL, MySQL, Oracle) from the connection string
3. **Analyze dependencies** — Introspects the database schema to discover all foreign key relationships referencing the target table
4. **Build dependency graph** — Constructs a directed acyclic graph of table dependencies using topological sort
5. **Generate deletion plan** — Creates an ordered list of tables to delete from, respecting FK constraints (children first, then parents)
6. **Display plan** — Shows a formatted table with the deletion order, table names, estimated row counts, and FK relationships
7. **Confirm** — Asks for user confirmation (unless `--no-confirm` is specified)
8. **Execute** — Performs batched bulk deletes in the correct order with real-time progress tracking
9. **Report** — Displays a summary of deleted rows, timing, and any errors

## Database Provider Detection

The provider is automatically detected from the connection string:

| Pattern in Connection String | Detected Provider |
|------------------------------|-------------------|
| `Server=` or `Data Source=` with `SqlClient` conventions | SQL Server |
| `Host=` or `Server=` with `Username=` | PostgreSQL |
| `Server=` with `Uid=` or `SslMode=` | MySQL |
| `Data Source=` with `User Id=` and TNS pattern | Oracle |

## Docker

### Build the image

```bash
# Using the build script
./scripts/build.sh

# With custom tag
./scripts/build.sh -t v1.0.0

# Build and push to registry
./scripts/build.sh -r registry.example.com -t v1.0.0 --push
```

### Run the container

```bash
# Run CLI in Docker
docker run --rm database-deletor \
  --connection-string "Server=host.docker.internal;Database=MyDb;User Id=sa;Password=pass;TrustServerCertificate=True" \
  --sql "DELETE FROM dbo.OldRecords" \
  --no-confirm
```

## Build Scripts

The `scripts/` directory contains universal build and deployment scripts:

| Script | Description |
|--------|-------------|
| `build.sh` | Docker image build script |
| `push.sh` | Git add, commit, and push workflow |
| `clean.sh` | Clean build artifacts (bin, obj, DEPLOYMENT) |
| `_buildDotnetSolution.sh` | Universal .NET build, test, and publish script |
| `_common.sh` | Shared utility functions for all scripts |

### Build the solution with the universal script

```bash
# Full build (restore + build + test + publish)
./scripts/_buildDotnetSolution.sh

# Build without tests
./scripts/_buildDotnetSolution.sh --no-test

# Build for Linux deployment
./scripts/_buildDotnetSolution.sh -r linux-x64 --self-contained
```

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Runtime | .NET | 10.0 |
| Data Access | Dapper | 2.1.66 |
| SQL Server Driver | Microsoft.Data.SqlClient | 6.0.1 |
| PostgreSQL Driver | Npgsql | 9.0.3 |
| MySQL Driver | MySqlConnector | 2.4.0 |
| Oracle Driver | Oracle.ManagedDataAccess.Core | 23.7.0 |
| CLI Framework | System.CommandLine | 2.0.0-beta5 |
| Console UI | Spectre.Console | 0.49.1 |
| Logging | Serilog | 4.2.0 |
| API Documentation | Swashbuckle.AspNetCore | 7.3.1 |
| Unit Testing | xUnit | 2.9.3 |
| Mocking | NSubstitute | 5.3.0 |
| Assertions | FluentAssertions | 8.1.1 |

## Development

### Project structure

```
DatabaseDeletor/
├── src/
│   ├── DatabaseDeletor.Domain/         # Entities, interfaces, enums
│   ├── DatabaseDeletor.Application/    # Commands, handlers, mediator
│   ├── DatabaseDeletor.Infrastructure/ # DB providers, Dapper queries
│   ├── DatabaseDeletor.Infrastructure.AI/ # AI/ML (Phase 2)
│   ├── DatabaseDeletor.Cli/           # CLI entry point
│   └── DatabaseDeletor.Api/           # REST API
├── tests/
│   ├── DatabaseDeletor.Domain.Tests/
│   ├── DatabaseDeletor.Application.Tests/
│   ├── DatabaseDeletor.Infrastructure.Tests/
│   ├── DatabaseDeletor.Cli.Tests/
│   └── DatabaseDeletor.Api.Tests/
├── docker/
│   └── Dockerfile
├── scripts/                           # Build & deployment scripts
├── docs/                              # Technical specifications
├── Directory.Build.props              # Shared MSBuild properties
├── Directory.Packages.props           # Central package management
└── DatabaseDeletor.sln
```

### Code quality

- `TreatWarningsAsErrors` enabled globally
- `AnalysisLevel` set to `latest-all` (all CA rules enforced)
- Central Package Management via `Directory.Packages.props`
- Nullable reference types enabled
- Implicit usings enabled

### Adding a new database provider

1. Create a connection factory in `Infrastructure/ConnectionFactories/` implementing `IDbConnectionFactory`
2. Create a schema introspector in `Infrastructure/SchemaIntrospectors/` implementing `ISchemaIntrospector`
3. Create a bulk delete executor in `Infrastructure/BulkDeleteExecutors/` implementing `IBulkDeleteExecutor`
4. Add the `DatabaseProvider` enum value in `Domain/Enums/DatabaseProvider.cs`
5. Register all three services in `Infrastructure/DependencyInjection.cs`
6. Add detection logic in `Infrastructure/Services/DatabaseProviderResolver.cs`

## License

Proprietary. All rights reserved.
