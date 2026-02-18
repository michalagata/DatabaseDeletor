# =============================================================================
# DatabaseDeletor Multi-Stage Dockerfile
# =============================================================================
# Target platform: linux/amd64
# Base: .NET 10 SDK (build) -> .NET 10 Runtime (final)
# Security: non-root user, read-only filesystem where feasible
# =============================================================================

# --- Stage 1: Build ---
FROM mcr.microsoft.com/dotnet/sdk:10.0-preview AS build
WORKDIR /src

# Copy solution and project files first for better layer caching
COPY DatabaseDeletor.sln ./
COPY Directory.Build.props ./
COPY Directory.Packages.props ./
COPY nuget.config ./

COPY src/DatabaseDeletor.Domain/DatabaseDeletor.Domain.csproj src/DatabaseDeletor.Domain/
COPY src/DatabaseDeletor.Application/DatabaseDeletor.Application.csproj src/DatabaseDeletor.Application/
COPY src/DatabaseDeletor.Infrastructure/DatabaseDeletor.Infrastructure.csproj src/DatabaseDeletor.Infrastructure/
COPY src/DatabaseDeletor.Infrastructure.AI/DatabaseDeletor.Infrastructure.AI.csproj src/DatabaseDeletor.Infrastructure.AI/
COPY src/DatabaseDeletor.Cli/DatabaseDeletor.Cli.csproj src/DatabaseDeletor.Cli/
COPY src/DatabaseDeletor.Api/DatabaseDeletor.Api.csproj src/DatabaseDeletor.Api/

# Restore dependencies (cached unless project files change)
RUN dotnet restore DatabaseDeletor.sln --runtime linux-x64

# Copy all source code
COPY src/ src/

# Build and publish CLI application
RUN dotnet publish src/DatabaseDeletor.Cli/DatabaseDeletor.Cli.csproj \
    --configuration Release \
    --runtime linux-x64 \
    --no-self-contained \
    --no-restore \
    --output /app/cli

# Build and publish API application
RUN dotnet publish src/DatabaseDeletor.Api/DatabaseDeletor.Api.csproj \
    --configuration Release \
    --runtime linux-x64 \
    --no-self-contained \
    --no-restore \
    --output /app/api

# --- Stage 2: Runtime (CLI) ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0-preview AS runtime
WORKDIR /app

# Install security updates
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --shell /bin/false --create-home appuser

# Copy published artifacts
COPY --from=build /app/cli ./cli
COPY --from=build /app/api ./api

# Create writable directories for logs and temp files
RUN mkdir -p /app/logs /app/data && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD dotnet /app/api/DatabaseDeletor.Api.dll --urls http://localhost:8080 || exit 1

# Default entrypoint is the CLI
ENTRYPOINT ["dotnet", "/app/cli/DatabaseDeletor.Cli.dll"]
