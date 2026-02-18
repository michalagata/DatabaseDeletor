#!/usr/bin/env zsh
set -Euo pipefail
IFS=$'\n\t'

# Run all Docker containers with full diagnostics
# Complete procedure: git pull, build images, start, comprehensive diagnostics, smoke tests, health checks, logs, error report
# This script performs full diagnostics and presents all errors at the end
# MAXIMUM EXECUTION TIME: 120 seconds - script will exit after this time regardless of status

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Maximum execution time: 120 seconds
MAX_EXECUTION_TIME=120
SCRIPT_START_TIME=$(date +%s)

# Function to check if timeout has been reached
check_timeout() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - SCRIPT_START_TIME))
    if [[ $elapsed -ge $MAX_EXECUTION_TIME ]]; then
        return 0  # Timeout reached
    fi
    return 1  # Timeout not reached
}

# Function to get remaining time
get_remaining_time() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - SCRIPT_START_TIME))
    echo $((MAX_EXECUTION_TIME - elapsed))
}

# Setup timeout handler
timeout_handler() {
    remaining=$(get_remaining_time)
    if [[ $remaining -le 0 ]]; then
        log_header "TIMEOUT REACHED - Script terminating after 120 seconds"
        error "Script execution exceeded maximum time limit of ${MAX_EXECUTION_TIME} seconds"
        error "Forcing exit..."
        exit 1
    fi
}

# Start background process to enforce timeout
(
    sleep $MAX_EXECUTION_TIME
    if ps -p $$ > /dev/null 2>&1; then
        log_header "TIMEOUT REACHED - Script terminating after 120 seconds"
        error "Script execution exceeded maximum time limit of ${MAX_EXECUTION_TIME} seconds"
        error "Forcing exit..."
        kill -TERM $$ 2>/dev/null || true
        sleep 1
        kill -KILL $$ 2>/dev/null || true
    fi
) &
TIMEOUT_PID=$!

# Cleanup timeout process on exit
cleanup_timeout() {
    kill $TIMEOUT_PID 2>/dev/null || true
}
trap cleanup_timeout EXIT

# Source common functions
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

# Read HOSTNAME
HOSTNAME_FILE="${PROJECT_ROOT}/HOSTNAME"
if [[ -f "$HOSTNAME_FILE" ]]; then
    HOSTNAME=$(cat "$HOSTNAME_FILE" | tr -d '\n\r' | xargs)
else
    HOSTNAME="localhost"
    warning "HOSTNAME file not found, using default: $HOSTNAME"
fi

# Ports configuration
API_PORT="${API_PORT:-8096}"

# Error tracking
ERRORS=()
WARNINGS=()

log_header "Running All Docker Containers with Full Diagnostics"

# Step 0: Complete cleanup - stop, remove containers, volumes, networks
step "Step 0: Complete cleanup of existing containers, volumes, and networks"
cd "$PROJECT_ROOT/infra"

info "Performing complete cleanup before rebuild..."

# Step 0.1: Stop and remove all containers (with volumes and networks)
info "Stopping and removing all containers..."
if docker compose ps -a 2>/dev/null | grep -qE "(Up|Exit|Created)"; then
    # First attempt: graceful shutdown with volumes and networks
    if docker compose down --volumes --remove-orphans 2>/dev/null; then
        success "Containers, volumes, and networks removed gracefully"
    else
        warning "docker compose down failed, attempting force stop..."
        # Force kill all containers
        docker compose kill 2>/dev/null || true
        # Remove containers forcefully
        docker compose rm -f 2>/dev/null || true
        # Try down again
        docker compose down --volumes --remove-orphans 2>/dev/null || true
        success "Containers force-stopped and removed"
    fi
else
    info "No containers found in docker compose"
fi

# Step 0.2: Remove any orphaned containers by name pattern
info "Checking for orphaned containers by name pattern..."
ORPHANED_CONTAINERS=$(docker ps -a --filter "name=anonymizer" --format "{{.Names}}" 2>/dev/null || true)
if [[ -n "$ORPHANED_CONTAINERS" ]]; then
    warning "Found orphaned containers: $ORPHANED_CONTAINERS"
    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            info "Stopping and removing orphaned container: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm -f "$container" 2>/dev/null || true
        fi
    done <<< "$ORPHANED_CONTAINERS"
    success "Orphaned containers removed"
else
    info "No orphaned containers found"
fi

# Step 0.3: Remove volumes associated with the project
info "Checking for project volumes..."
PROJECT_VOLUMES=$(docker volume ls --filter "name=anonymizer" --format "{{.Name}}" 2>/dev/null || true)
if [[ -n "$PROJECT_VOLUMES" ]]; then
    warning "Found project volumes: $PROJECT_VOLUMES"
    while IFS= read -r volume; do
        if [[ -n "$volume" ]]; then
            info "Removing volume: $volume"
            docker volume rm -f "$volume" 2>/dev/null || true
        fi
    done <<< "$PROJECT_VOLUMES"
    success "Project volumes removed"
else
    info "No project volumes found"
fi

# Step 0.4: Remove networks associated with the project
info "Checking for project networks..."
PROJECT_NETWORKS=$(docker network ls --filter "name=anonymizer" --format "{{.Name}}" 2>/dev/null || true)
if [[ -n "$PROJECT_NETWORKS" ]]; then
    warning "Found project networks: $PROJECT_NETWORKS"
    while IFS= read -r network; do
        if [[ -n "$network" ]]; then
            info "Removing network: $network"
            docker network rm "$network" 2>/dev/null || true
        fi
    done <<< "$PROJECT_NETWORKS"
    success "Project networks removed"
else
    info "No project networks found"
fi

# Step 0.5: Verify cleanup - check if anything remains
info "Verifying complete cleanup..."
REMAINING_CONTAINERS=$(docker compose ps -a 2>/dev/null | grep -qE "(Up|Exit|Created)" && echo "yes" || echo "no")
if [[ "$REMAINING_CONTAINERS" == "yes" ]]; then
    warning "Some containers may still exist, attempting final cleanup..."
    docker compose kill 2>/dev/null || true
    docker compose rm -f 2>/dev/null || true
    docker compose down --volumes --remove-orphans 2>/dev/null || true
else
    success "All containers verified removed"
fi

# Step 0.6: Optional - clean build cache (commented out by default to preserve build speed)
# Uncomment the following lines if you want to clean build cache every time:
# info "Cleaning Docker build cache..."
# docker builder prune -f 2>/dev/null || true
# success "Build cache cleaned"

success "Complete cleanup finished - ready for fresh build"

# Step 1: Git pull
step "Step 1: Git pull"
if [[ -d "$PROJECT_ROOT/.git" ]]; then
    cd "$PROJECT_ROOT"
    if git pull; then
        success "Git pull completed"
    else
        warning "Git pull failed or no changes"
    fi
else
    info "Not a git repository, skipping git pull"
fi

# Step 2: Prepare appsettings.json
step "Step 2: Preparing appsettings.json"
if "$SCRIPT_DIR/_prepareEnvGlobalFile.sh"; then
    success "appsettings.json prepared"
else
    error "Failed to prepare appsettings.json"
fi

# Step 3: Build base image
step "Step 3: Building base Docker image"
if "$SCRIPT_DIR/_buildBaseDocker.sh"; then
    success "Base image built"
else
    error "Failed to build base image"
fi

# Step 4: Build application images
step "Step 4: Building application Docker images"
if "$SCRIPT_DIR/_buildDocker.sh"; then
    success "Application images built"
else
    error "Failed to build application images"
fi

# Step 5: Start containers
step "Step 5: Starting Docker Compose"
cd "$PROJECT_ROOT/infra"
if docker compose up -d; then
    success "Containers started"
else
    error "Failed to start containers"
fi

# Step 6: Wait for services to be ready
step "Step 6: Waiting for services to be ready"
sleep 10
info "Waiting for health checks..."

# Step 7: Full diagnostics
step "Step 7: Running full diagnostics"
info "Running comprehensive diagnostics..."

# Run diagnostics script if available
if [[ -f "$SCRIPT_DIR/_diagnostics.sh" ]]; then
    if "$SCRIPT_DIR/_diagnostics.sh" --url "http://${HOSTNAME}:${API_PORT}"; then
        success "Diagnostics completed"
    else
        ERRORS+=("Diagnostics script failed")
        warning "Diagnostics script reported issues"
    fi
else
    warning "_diagnostics.sh not found, running basic diagnostics"
fi

# Step 8: Wait for services to be ready and verify healthchecks (with timeout check)
step "Step 8: Waiting for services to be ready and verifying healthchecks"
info "Waiting for API to be ready on port ${API_PORT}..."
info "Remaining time: $(get_remaining_time) seconds"

# First, wait for API to become available (max 30 seconds or until timeout)
API_READY=false
MAX_WAIT_ATTEMPTS=15
for i in $(seq 1 $MAX_WAIT_ATTEMPTS); do
    if check_timeout; then
        warning "Timeout reached while waiting for API"
        break
    fi
    
    if curl -s -f "http://${HOSTNAME}:${API_PORT}/healthz" > /dev/null 2>&1; then
        info "API is ready (attempt $i/$MAX_WAIT_ATTEMPTS)"
        API_READY=true
        break
    else
        remaining=$(get_remaining_time)
        if [[ $remaining -le 5 ]]; then
            warning "Less than 5 seconds remaining, skipping further API wait attempts"
            break
        fi
        info "Attempt $i/$MAX_WAIT_ATTEMPTS: Waiting for API... (remaining: ${remaining}s)"
        sleep 2
    fi
done

if [[ "$API_READY" != "true" ]]; then
    ERRORS+=("API did not become ready within available time")
    warning "API readiness check failed"
    HEALTHCHECK_STABLE=false
else
    # Now verify healthchecks are stable (reduced time to fit in 120s total)
    remaining=$(get_remaining_time)
    if [[ $remaining -lt 20 ]]; then
        info "Limited time remaining (${remaining}s), performing quick healthcheck verification..."
        HEALTHCHECK_STABLE=true
        CHECK_INTERVAL=2
        TOTAL_CHECKS=$((remaining / CHECK_INTERVAL))
        if [[ $TOTAL_CHECKS -gt 5 ]]; then
            TOTAL_CHECKS=5  # Max 5 checks
        fi
    else
        info "Verifying healthchecks are stable (up to 20 seconds)..."
        HEALTHCHECK_STABLE=true
        CHECK_INTERVAL=4
        TOTAL_CHECKS=5  # 5 checks * 4s = 20 seconds max
    fi
    
    FAILED_CHECKS=0

    for i in $(seq 1 $TOTAL_CHECKS); do
        if check_timeout; then
            warning "Timeout reached during healthcheck verification"
            break
        fi
        
        remaining=$(get_remaining_time)
        if [[ $remaining -le 2 ]]; then
            warning "Less than 2 seconds remaining, stopping healthcheck verification"
            break
        fi
        
        if curl -s -f "http://${HOSTNAME}:${API_PORT}/healthz" > /dev/null 2>&1 && \
           curl -s -f "http://${HOSTNAME}:${API_PORT}/readyz" > /dev/null 2>&1; then
            if [[ $((i % 2)) -eq 0 ]] || [[ $i -eq 1 ]] || [[ $i -eq $TOTAL_CHECKS ]]; then
                info "Healthcheck $i/$TOTAL_CHECKS: OK (remaining: ${remaining}s)"
            fi
        else
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            warning "Healthcheck $i/$TOTAL_CHECKS: FAILED"
            if [[ $FAILED_CHECKS -gt 2 ]]; then
                HEALTHCHECK_STABLE=false
                ERRORS+=("Healthchecks failed $FAILED_CHECKS times during stability check")
                break
            fi
        fi
        if [[ $i -lt $TOTAL_CHECKS ]]; then
            sleep $CHECK_INTERVAL
        fi
    done

    if [[ "$HEALTHCHECK_STABLE" == "true" ]]; then
        success "Healthchecks verified"
    else
        warning "Healthchecks were not stable"
    fi
fi

# Step 9: Smoke tests (skip if timeout is near)
step "Step 9: Running smoke tests"
remaining=$(get_remaining_time)
if [[ $remaining -lt 10 ]]; then
    warning "Less than 10 seconds remaining, skipping smoke tests"
    SMOKE_PASSED=false
    WARNINGS+=("Smoke tests skipped due to time limit")
else
    # Get API key from appsettings.json if not set
    if [[ -z "${AUTH_TOKEN:-}" ]]; then
        if [[ -f "$PROJECT_ROOT/appsettings.json" ]]; then
            AUTH_TOKEN=$(jq -r '.Auth.ApiKey // empty' "$PROJECT_ROOT/appsettings.json" 2>/dev/null || echo "")
        fi
    fi

    # Run comprehensive smoke tests (with timeout)
    SMOKE_PASSED=false
    if [[ -f "$SCRIPT_DIR/_smokeAll.sh" ]]; then
        if [[ -n "${AUTH_TOKEN:-}" ]]; then
            if timeout $remaining "$SCRIPT_DIR/_smokeAll.sh" --url "http://${HOSTNAME}:${API_PORT}" --token "$AUTH_TOKEN" 2>/dev/null || \
               "$SCRIPT_DIR/_smokeAll.sh" --url "http://${HOSTNAME}:${API_PORT}" --token "$AUTH_TOKEN"; then
                success "All smoke tests passed"
                SMOKE_PASSED=true
            else
                ERRORS+=("Smoke tests failed (with authentication)")
                warning "Some smoke tests failed"
            fi
        else
            if timeout $remaining "$SCRIPT_DIR/_smokeAll.sh" --url "http://${HOSTNAME}:${API_PORT}" 2>/dev/null || \
               "$SCRIPT_DIR/_smokeAll.sh" --url "http://${HOSTNAME}:${API_PORT}"; then
                success "Smoke tests passed (unauthenticated)"
                SMOKE_PASSED=true
            else
                ERRORS+=("Smoke tests failed (unauthenticated)")
                warning "Some smoke tests failed"
            fi
        fi
    else
        warning "_smokeAll.sh not found, running basic health checks"
        if curl -s -f "http://${HOSTNAME}:${API_PORT}/healthz" > /dev/null && \
           curl -s -f "http://${HOSTNAME}:${API_PORT}/readyz" > /dev/null; then
            success "Basic health checks passed"
            SMOKE_PASSED=true
        else
            ERRORS+=("Basic health checks failed")
            error "Basic health checks failed"
        fi
    fi
fi

# Step 10: Health check (quick check if time allows)
step "Step 10: Health check"
remaining=$(get_remaining_time)
if [[ $remaining -lt 5 ]]; then
    warning "Less than 5 seconds remaining, skipping final health checks"
else
    if curl -s -f "http://${HOSTNAME}:${API_PORT}/readyz" > /dev/null; then
        success "Readiness check passed"
    else
        ERRORS+=("Readiness check failed")
        error "Readiness check failed"
    fi

    # Check Swagger endpoint (now on same port as API)
    if curl -s -f "http://${HOSTNAME}:${API_PORT}/swagger" > /dev/null 2>&1; then
        success "Swagger endpoint accessible"
    else
        WARNINGS+=("Swagger endpoint not accessible")
        warning "Swagger endpoint check failed"
    fi
fi

# Step 11: Show recent logs (no follow, just tail) - only if time allows
step "Step 11: Showing recent logs"
remaining=$(get_remaining_time)
if [[ $remaining -ge 3 ]]; then
    cd "$PROJECT_ROOT/infra"
    info "Recent container logs (last 30 lines):"
    docker compose logs --tail=30 2>&1 || warning "Could not retrieve logs"
else
    warning "Skipping logs display due to time limit"
fi

# Step 12: Final report with error summary (quick summary if time allows)
log_header "Final Report - Error Summary"
remaining=$(get_remaining_time)
if [[ $remaining -ge 5 ]]; then
    info "Service status:"
    cd "$PROJECT_ROOT/infra"
    docker compose ps 2>/dev/null || warning "Could not get service status"
    
    info "Health endpoints:"
    if curl -s -f "http://${HOSTNAME}:${API_PORT}/healthz" > /dev/null 2>&1; then
        curl -s "http://${HOSTNAME}:${API_PORT}/healthz" | jq . 2>/dev/null || echo "  (unable to parse)"
    else
        ERRORS+=("Health endpoint not accessible")
    fi
    
    if curl -s -f "http://${HOSTNAME}:${API_PORT}/readyz" > /dev/null 2>&1; then
        curl -s "http://${HOSTNAME}:${API_PORT}/readyz" | jq . 2>/dev/null || echo "  (unable to parse)"
    else
        ERRORS+=("Readiness endpoint not accessible")
    fi
else
    warning "Skipping detailed final report due to time limit"
fi

# Error summary
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    log_header "ERRORS DETECTED"
    for err in "${ERRORS[@]}"; do
        error "  - $err"
    done
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    log_header "WARNINGS"
    for warn in "${WARNINGS[@]}"; do
        warning "  - $warn"
    done
fi

# Final status
log_header "Final Status"
elapsed=$(( $(date +%s) - SCRIPT_START_TIME ))
info "Script execution time: ${elapsed} seconds (max: ${MAX_EXECUTION_TIME}s)"

# Display all service URLs
log_header "Service URLs"
info ""
info "═══════════════════════════════════════════════════════════════"
info "  🌐 WEB INTERFACE (Angular UI)"
info "═══════════════════════════════════════════════════════════════"
info "  URL:        http://${HOSTNAME}:${API_PORT}"
info "  Dashboard:  http://${HOSTNAME}:${API_PORT}/"
info ""
info "═══════════════════════════════════════════════════════════════"
info "  🔌 API ENDPOINTS"
info "═══════════════════════════════════════════════════════════════"
info "  Base URL:   http://${HOSTNAME}:${API_PORT}/api/v1"
info "  Health:     http://${HOSTNAME}:${API_PORT}/healthz"
info "  Readiness:  http://${HOSTNAME}:${API_PORT}/readyz"
info "  Metrics:    http://${HOSTNAME}:${API_PORT}/metrics"
info ""
info "═══════════════════════════════════════════════════════════════"
info "  📚 SWAGGER DOCUMENTATION"
info "═══════════════════════════════════════════════════════════════"
info "  Swagger UI: http://${HOSTNAME}:${API_PORT}/swagger"
info "  Swagger JSON: http://${HOSTNAME}:${API_PORT}/swagger/v1/swagger.json"
info ""
info "═══════════════════════════════════════════════════════════════"
info "  🔐 AUTHENTICATION"
info "═══════════════════════════════════════════════════════════════"
info "  Generate Token: POST http://${HOSTNAME}:${API_PORT}/api/v1/generate-token"
info "  Validate Variables: POST http://${HOSTNAME}:${API_PORT}/api/v1/validate-variables"
info ""
info "═══════════════════════════════════════════════════════════════"
info "  📊 MAIN API ENDPOINTS"
info "═══════════════════════════════════════════════════════════════"
info "  Anonymize:  POST http://${HOSTNAME}:${API_PORT}/api/v1/anonymize"
info "  Checksum:   POST http://${HOSTNAME}:${API_PORT}/api/v1/checksum"
info "  Training:   POST http://${HOSTNAME}:${API_PORT}/api/v1/training"
info "  Models:     GET  http://${HOSTNAME}:${API_PORT}/api/v1/models"
info "  Cache:      GET  http://${HOSTNAME}:${API_PORT}/api/v1/cache"
info "  Logs:       GET  http://${HOSTNAME}:${API_PORT}/api/v1/logs"
info "  Audit:      GET  http://${HOSTNAME}:${API_PORT}/api/v1/audit"
info ""
info "═══════════════════════════════════════════════════════════════"

if [[ ${#ERRORS[@]} -eq 0 && "$SMOKE_PASSED" == "true" && "$HEALTHCHECK_STABLE" == "true" ]]; then
    success "All services are running and healthy"
    info ""
    info "All containers are up and healthchecks are stable."
    info "Script completed successfully."
    # Cleanup timeout process before exit
    cleanup_timeout
    exit 0
else
    error "Some services are not healthy or errors detected"
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        error "Total errors: ${#ERRORS[@]}"
    fi
    if [[ "$HEALTHCHECK_STABLE" != "true" ]]; then
        error "Healthchecks were not stable"
    fi
    if [[ "$SMOKE_PASSED" != "true" ]]; then
        error "Smoke tests failed"
    fi
    info ""
    warning "Service URLs are displayed above, but some services may not be fully operational."
    # Cleanup timeout process before exit
    cleanup_timeout
    exit 1
fi

