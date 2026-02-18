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
- **Feature toggles** — Runtime configuration for Swagger, health checks, deletion/analysis endpoints, and external communication
- **OpenTelemetry** — Distributed tracing and metrics (conditional on feature toggles)
- **Self-contained deployment** — Native executables for linux-x64, osx-arm64, win-x64 (no .NET runtime required)
- **Clean Architecture** — Domain-driven design with CQRS command/handler pattern

## Product Guide

### What Does DatabaseDeletor Do?

DatabaseDeletor solves a common and dangerous problem: **deleting rows from a database table that has foreign key dependencies**. Instead of manually tracing FK chains and writing DELETE statements in the correct order, DatabaseDeletor:

1. Parses your SQL to identify the target table
2. Automatically introspects the database schema to discover **all** foreign key relationships pointing to that table (and their transitive dependencies)
3. Builds a dependency graph and generates a **safe deletion order** (children first, then parents)
4. Executes batched bulk deletes in the correct order with progress tracking

This means you provide a single `DELETE FROM` statement, and DatabaseDeletor handles the entire FK chain automatically.

### SQL Query Syntax

DatabaseDeletor accepts two SQL statement formats:

#### DELETE FROM syntax

```sql
DELETE FROM schema.table WHERE condition
```

Examples:
```sql
DELETE FROM dbo.Orders WHERE OrderDate < '2020-01-01'
DELETE FROM public.audit_logs WHERE created_at < '2024-01-01'
DELETE FROM myschema.sessions WHERE expired = 1
DELETE FROM Users WHERE IsActive = 0
```

#### SELECT FROM syntax

You can also use `SELECT FROM` to target a table — DatabaseDeletor extracts the table name the same way:

```sql
SELECT * FROM dbo.Orders WHERE OrderDate < '2020-01-01'
SELECT id FROM public.logs WHERE level = 'DEBUG'
```

This is useful when you want to preview which table will be targeted without writing a DELETE statement.

### Table Name Formats

Table names can use any of these quoting conventions, depending on the database provider:

| Format | Example | Provider |
|--------|---------|----------|
| Unquoted | `dbo.Orders` | Any |
| Square brackets | `[dbo].[Orders]` | SQL Server |
| Double quotes | `"public"."orders"` | PostgreSQL |
| Backticks | `` `mydb`.`orders` `` | MySQL |

Table name resolution rules:
- **1-part name** (`Orders`) — Schema defaults to `dbo`
- **2-part name** (`public.orders`) — Interpreted as `schema.table`
- **3-part name** (`myserver.dbo.Orders`) — Interpreted as `server.schema.table` (server part is ignored)

All quoting characters (`[]`, `""`, `` ` ``) are stripped automatically before processing.

### Connection Strings by Provider

DatabaseDeletor auto-detects the database provider from the connection string format. No `--provider` flag is needed.

#### SQL Server

```
Server=localhost;Database=MyDatabase;User Id=sa;Password=YourPassword;TrustServerCertificate=True
```

Detection keywords: `Server=` + `Database=` (without `Port=`/`Host=`), or `Data Source=` + `Initial Catalog=`, or containing `SqlServer`.

#### PostgreSQL

```
Host=localhost;Database=mydb;Username=postgres;Password=secret
```

Detection keywords: `Host=` + `Database=` (without `Data Source=`), or containing `Npgsql`/`Postgres`.

#### MySQL

```
Server=localhost;Port=3306;Database=mydb;Uid=root;Pwd=secret;SslMode=Preferred
```

Detection keywords: `Server=` + `Database=` + `Port=`, or containing `MySQL`.

#### Oracle

```
Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SID=ORCL)));User Id=system;Password=secret
```

Detection keywords: `Data Source=` + `User Id=` with TNS pattern, or containing `Oracle`/`TNS_ADMIN`.

### CLI Usage

#### Basic syntax

```bash
database-deletor --connection-string "<conn>" --sql "<query>" [options]
```

Or using `dotnet run` during development:

```bash
dotnet run --project src/DatabaseDeletor.Cli -- --connection-string "<conn>" --sql "<query>" [options]
```

#### CLI Options

| Option | Short | Required | Default | Description |
|--------|-------|----------|---------|-------------|
| `--connection-string` | `-c` | Yes | — | Full database connection string |
| `--sql` | `-s` | Yes | — | SQL query targeting the table (`DELETE FROM` or `SELECT FROM`) |
| `--no-confirm` | `-y` | No | `false` | Skip confirmation prompt and execute immediately |
| `--batch-size` | `-b` | No | `10000` | Number of rows to delete per batch |
| `--verbose` | `-v` | No | `false` | Enable debug-level logging output |

#### Real-World Examples

**1. Clean up old orders from SQL Server (interactive mode)**

```bash
database-deletor \
  -c "Server=prod-db.internal;Database=ECommerce;User Id=admin;Password=s3cret;TrustServerCertificate=True" \
  -s "DELETE FROM dbo.Orders WHERE OrderDate < '2020-01-01'"
```

The tool will:
1. Parse the SQL and identify `dbo.Orders` as the target
2. Connect to the database and discover all FK references (e.g., `OrderItems`, `Payments`, `Shipments` referencing `Orders`)
3. Display a table showing the deletion plan with estimated row counts per table
4. Ask for confirmation before executing
5. Delete rows in safe order: `Shipments` → `Payments` → `OrderItems` → `Orders`

**2. GDPR data purge from PostgreSQL (automated, no prompt)**

```bash
database-deletor \
  -c "Host=pg-primary.internal;Database=userdata;Username=app_admin;Password=secret" \
  -s "DELETE FROM public.users WHERE deletion_requested_at IS NOT NULL" \
  --no-confirm \
  --batch-size 5000
```

Uses `--no-confirm` for automation (e.g., cron jobs or CI pipelines) and smaller batch size to reduce lock contention.

**3. Purge audit logs from MySQL with verbose output**

```bash
database-deletor \
  -c "Server=mysql.internal;Port=3306;Database=app_logs;Uid=root;Pwd=secret;SslMode=Preferred" \
  -s "DELETE FROM audit_trail WHERE event_date < '2023-01-01'" \
  --verbose
```

Verbose mode outputs debug-level logs including SQL statements being executed, timing per batch, and FK discovery details.

**4. Clean up Oracle test data**

```bash
database-deletor \
  -c "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oracle.internal)(PORT=1521))(CONNECT_DATA=(SID=TESTDB)));User Id=system;Password=oracle" \
  -s "DELETE FROM HR.EMPLOYEES WHERE DEPARTMENT_ID = 999" \
  -y -b 20000
```

Uses short flags (`-y` for no-confirm, `-b` for batch size) and a larger batch size for Oracle bulk operations.

**5. Target a table using SELECT syntax**

```bash
database-deletor \
  -c "Server=localhost;Database=MyDb;User Id=sa;Password=pass;TrustServerCertificate=True" \
  -s "SELECT * FROM dbo.TempRecords WHERE CreatedAt < '2024-06-01'"
```

Useful when you already have a SELECT query and want to delete all dependent data for that table without rewriting it as DELETE.

### Batch Size Tuning

The `--batch-size` parameter controls how many rows are deleted per database round-trip. The default is `10,000` rows.

| Scenario | Recommended Batch Size | Rationale |
|----------|----------------------|-----------|
| General use | `10000` (default) | Balanced throughput vs. lock duration |
| High-contention OLTP tables | `1000` – `5000` | Shorter lock windows, less blocking |
| Large cleanup jobs (off-hours) | `50000` – `100000` | Maximize throughput when locks are acceptable |
| Tables with large rows (BLOBs) | `500` – `2000` | Avoid transaction log overflow |
| Oracle (ROWNUM-based) | `10000` – `50000` | Oracle handles large batches well |

Each batch is a single transaction. If a batch fails, only that batch is rolled back — previously completed batches remain deleted.

### How Deletion Works Internally

For each table in the deletion plan, DatabaseDeletor uses provider-specific optimized SQL:

| Provider | Batch Delete Strategy | Example SQL |
|----------|-----------------------|-------------|
| SQL Server | `DELETE TOP(@n)` | `DELETE TOP(10000) FROM [dbo].[Orders] WHERE OrderDate < '2020-01-01'` |
| PostgreSQL | `ctid` subquery | `DELETE FROM "orders" WHERE ctid IN (SELECT ctid FROM "orders" WHERE ... LIMIT 10000)` |
| MySQL | `LIMIT` clause | `` DELETE FROM `orders` WHERE ... LIMIT 10000 `` |
| Oracle | `ROWNUM` wrapper | `DELETE FROM "ORDERS" WHERE ROWNUM <= 10000 AND ...` |

The tool loops until zero rows are affected in a batch, then moves to the next table in the plan.

### What Happens Without a WHERE Clause

If your SQL does not include a WHERE clause (e.g., `DELETE FROM dbo.Orders`), DatabaseDeletor will:

1. Display a warning: **"No WHERE clause detected — ALL rows will be targeted"**
2. Still show the deletion plan with estimated row counts
3. Ask for confirmation (unless `--no-confirm` is set)

This is by design — sometimes you need to empty an entire table and all its dependents.

### Logging

Logs are written to rolling daily files at `logs/database-deletor-YYYY-MM-DD.log`.

Log levels:
- **Information** (default): Key steps, deletion plan, batch progress summaries
- **Debug** (`--verbose`): SQL statements, FK discovery details, timing per batch, full dependency graph

Log format: `2026-02-18 14:30:22.456 +01:00 [INF] Deleting 10000 rows from dbo.OrderItems (batch 3/12)`

### REST API

The API exposes the same functionality over HTTP with Swagger documentation.

```bash
# Start the API server
dotnet run --project src/DatabaseDeletor.Api

# Health check
curl http://localhost:5000/health

# Swagger UI
open http://localhost:5000/swagger
```

The API supports feature toggles via `appsettings.json` — see [Feature Toggles](#feature-toggles).

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
| `DatabaseDeletor.Cli` | Console App | CLI entry point with System.CommandLine + Spectre.Console |
| `DatabaseDeletor.Api` | Web App | Minimal API with Swagger, health check endpoint |
| `DatabaseDeletor.Domain.Tests` | xUnit Tests | 70 unit tests for domain entities and value objects |
| `DatabaseDeletor.Application.Tests` | xUnit Tests | 36 unit tests for handlers, mediator, DI, SQL parser |
| `DatabaseDeletor.Infrastructure.Tests` | xUnit Tests | 64 unit tests for providers, introspectors, executors, DI |
| `DatabaseDeletor.Cli.Tests` | xUnit Tests | 13 tests for DeletionService and ConsoleRenderer |
| `DatabaseDeletor.Api.Tests` | xUnit Tests | 20 tests for startup, health, Swagger, feature toggles, config validation |

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
# Run all 203 tests
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
| `Server=` + `Database=` (without `Port=`/`Host=`) | SQL Server |
| `Data Source=` + `Initial Catalog=` | SQL Server |
| `Host=` + `Database=` (without `Data Source=`) | PostgreSQL |
| `Server=` + `Database=` + `Port=` | MySQL |
| `Data Source=` + `User Id=` with TNS pattern | Oracle |

## Self-Contained Deployment

The CLI and API are published as self-contained native executables — no .NET runtime is required on the target machine.

```bash
# Publish for Linux
dotnet publish src/DatabaseDeletor.Cli/DatabaseDeletor.Cli.csproj -c Release -r linux-x64

# Publish for macOS (Apple Silicon)
dotnet publish src/DatabaseDeletor.Cli/DatabaseDeletor.Cli.csproj -c Release -r osx-arm64

# Publish for Windows
dotnet publish src/DatabaseDeletor.Cli/DatabaseDeletor.Cli.csproj -c Release -r win-x64
```

The Docker image uses `runtime-deps` as the base (not `aspnet`), since the executables are self-contained.

## Feature Toggles

The API supports runtime feature toggles via `appsettings.json`:

| Toggle | Default | Description |
|--------|---------|-------------|
| `SwaggerEnabled` | `true` | Enable/disable Swagger UI and JSON endpoint |
| `HealthCheckEnabled` | `true` | Enable/disable `/health` endpoint |
| `DeletionEndpointsEnabled` | `true` | Enable/disable deletion API endpoints |
| `AnalysisEndpointsEnabled` | `true` | Enable/disable analysis API endpoints |
| `NoExternalCommunication` | `false` | Block all outbound HTTP and disable OpenTelemetry exporters |

```json
{
  "FeatureToggles": {
    "SwaggerEnabled": true,
    "NoExternalCommunication": false
  }
}
```

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
| Observability | OpenTelemetry | 1.12.0 |
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
