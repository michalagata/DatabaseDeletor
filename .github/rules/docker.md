
# RULE SET: DOCKER
> Description: General rules

# Docker / Shell Scripts — Final Operational Rules (v2025-09-16T08:33:09Z)

## Scope
Applies to all deliverables that generate or modify shell scripts (`*.sh`) and Docker-related automation within this project/repository.

---

## 1) **Template-First Rule (Critical)**
**When generating any required `*.sh` script:**
1. **First** use the appropriate **template** from the `scripts/` directory (match by target filename).
2. If **no exact match** exists, use `scripts/_template.sh` as the base.
3. **Only if the `scripts/` directory has no suitable template**, generate the script from scratch.
4. After copying a template: fill all `TODO:` sections and keep the safety header (`#!/usr/bin/env bash`, `set -Eeuo pipefail`, `trap` on `ERR`), `usage`, `run`, and idempotent semantics.
5. All of Dockerfiles must be inside propper subdirectory of "docker" directory, all the building, tagging, versioning, push and run scripts must be tuned for this location.

This rule **takes precedence** over any other guidance.

---

## 2) **Canonical Script Set & Naming (No Duplicates)**
Produce **exactly one** canonical script per action (no copies like `_buildDocker_2.sh`):
- `_buildDocker.sh`
- `_publishDocker.sh`
- `_startDocker.sh`
- `_stopDocker.sh`
- `_restartDocker.sh`
- `_logsDocker.sh`
- `_cleanDocker.sh`
- Helpers: `_common.sh`, `_load_env.sh`, `_compat.sh` (compatibility shim), optional smoke tests: `_smokeBuildDocker.sh`, `_smokeStartDocker.sh`, `_smokeAllDocker.sh`.

**If multiple legacy variants exist**, **merge** their features into the single canonical script (superset behavior). Document any special flags as **environment variables**, not hard-coded logic.

---

## 3) **Shell Script Quality Baseline (English-only)**
Every script (including templates and generated ones) must:
- Start with:
  - `#!/usr/bin/env bash`
  - `set -Eeuo pipefail`
  - `trap 'ret=$?; echo "[ERROR] $(basename "$0") failed with code $ret" >&2; exit $ret' ERR`
- Provide `usage()` with `--help`, `--dry-run`, `--verbose` (`TRACE=1`).
- Provide `run()` wrapper (honors `DRY_RUN`).
- Prefer idempotency and safe defaults.
- Use Unix LF newlines and POSIX-compliant flags where possible.
- Be **English-only** (comments, help, messages).

---

## 4) **Feature Superset — Expected Options**
Consolidated scripts must expose features via **env vars**:

### Build (`_buildDocker.sh`)
- `DOCKER_IMAGE`, `DOCKER_TAG`, `DOCKERFILE`, `CONTEXT`
- `PLATFORMS` (enables `buildx`), `PUSH`, `LOAD`
- `NO_CACHE`, `CACHE_FROM`, `CACHE_TO`
- `BUILD_ARGS` (`"KEY=VAL KEY2=VAL2"`), `LABELS` (`"key=val key2=val2"`)
- `TARGET`, `PROGRESS` (`auto|plain|tty`), `ADDITIONAL_FLAGS`
- Extended: `SQUASH=1`, `PULL=1`, `SSH_AGENT=path`, `SECRETS="id=path ..."`, `PROVENANCE=value`, `SBOM=value`

### Publish (`_publishDocker.sh`)
- `DOCKER_IMAGE` (required), `DOCKER_TAG` **or** `TAGS`
- Optional registry login: `DOCKER_REGISTRY`, `LOGIN_USER`, `LOGIN_PASS`, `DOCKER_CONFIG`
- `ADDITIONAL_FLAGS` forwarded to `docker push`

### Start (`_startDocker.sh`)
- `CONTAINER_NAME`, `IMAGE`
- `PORTS`, `ENVS`, `ENV_FILE`, `ENV_FILES` (multiple)
- `VOLUMES`, `NETWORK`, `CREATE_NETWORK`, `RESTART`
- `HEALTH_WAIT`, `HEALTH_TIMEOUT`
- `ARGS` passthrough
- Extended: `HOST_NETWORK`, `ADD_HOSTS`, `GPUS`, `PRIVILEGED`, `CAP_ADD`, `SYSCTLS`, `ULIMITS`, `DEVICES`, `TMPFS`, `WORKDIR`, `ENTRYPOINT`, `CPUS`, `MEMORY`

### Stop / Restart / Logs / Clean
- Stop: `CONTAINER_NAME`, `REMOVE_VOLUMES`
- Restart: `CONTAINER_NAME` (start if missing)
- Logs: `CONTAINER_NAME`, `FOLLOW`, `TAIL`, `SINCE`
- Clean: `PRUNE_ALL`, `PRUNE_BUILDX`, `PRUNE_VOLUMES`, `CONFIRM`

---

## 5) **Compatibility Shim (`_compat.sh`)**
Provide `_compat.sh` that maps common legacy env names to the new ones **without overriding** already-set new vars. Examples:
- `IMAGE_NAME|IMAGE → DOCKER_IMAGE`
- `IMAGE_TAG|TAG → DOCKER_TAG`
- `REGISTRY|REGISTRY_URL|REGISTRY_HOST|REGISTRY_SERVER → DOCKER_REGISTRY`
- `REGISTRY_USER(NAME) → LOGIN_USER`, `REGISTRY_PASSWORD|REGISTRY_TOKEN → LOGIN_PASS`
- `CONTAINER|NAME → CONTAINER_NAME`
- `PORT_LIST|CONTAINER_PORTS → PORTS`
- `ENV_VARS → ENVS`, `ENVFILE|ENV_FILE_PATH → ENV_FILE`
- `VOLUME_LIST → VOLUMES`
- `DOCKER_NETWORK|NETWORK_NAME → NETWORK`
- `HEALTHCHECK_WAIT|WAIT_FOR_HEALTH → HEALTH_WAIT`, `HEALTH_TIMEOUT_SECONDS → HEALTH_TIMEOUT`
- `CPU_LIMIT → CPUS`, `MEMORY_LIMIT → MEMORY`

All canonical scripts must `source` `_compat.sh` if present.

---

## 6) **Smoke Tests (Required for CI sanity)**
Ship and wire simple, fast tests:
- `_smokeBuildDocker.sh` — inline tiny build (BusyBox) **or** `--use-project` to call `_buildDocker.sh`.
- `_smokeStartDocker.sh` — inline ephemeral run **or** `--use-project` to call `_startDocker.sh`.
- `_smokeAllDocker.sh` — orchestrates both.

These tests must run without external project files (inline mode), yet prefer project scripts when `--use-project` is supplied.

---

## 7) **Documentation & Packaging**
- Include `README.md` in the scripts package explaining variables, examples, and smoke tests.
- Preserve executable bits in archives.
- Output artifacts as ZIPs with deterministic structure:
  - `script-templates.zip` (templates, EN-only),
  - `scripts_consolidated_v2.zip` (canonical scripts + `_compat.sh`),
  - `docker-smoke-tests.zip` (smoke tests).
- Reference these artifacts in deliverables; do **not** duplicate them inline unless requested.

---

## 8) **Validation Checklist (must pass)**
- [ ] Template-first selection was applied (or lack of template justified).
- [ ] No duplicate canonical scripts produced.
- [ ] English-only; strict Bash mode & `trap` present.
- [ ] `usage/--help`, `--dry-run`, `--verbose` supported.
- [ ] Feature superset exposed via env vars (no hard-coded project specifics).
- [ ] `_compat.sh` present & sourced by canonical scripts.
- [ ] Smoke tests included and runnable both inline and project modes.
- [ ] Executable bits preserved in ZIPs; README present.

---

## 9) **Change Control**
When consolidating multiple legacy variants, record decisions (mapping → env flags) in the package `README.md` and keep a short migration note. Do not remove project-specific behavior—parameterize it.

---

<!-- BEGIN: DOCKER_TWO_IMAGE_PROMPT -->
## LLM Prompt — Docker two-image build optimization

**Role:** Senior Docker Architect  
**Mission:** Optimize Docker builds for fast rebuilds by splitting the image into at least two images and leveraging cache effectively.

**Hard Requirements (Non‑Negotiable)**
1. Build **minimum two images**:
   - `base` image: contains OS deps, heavy system libraries, language runtimes, compilers and stable, rarely-changing packages.
   - `app` image: `FROM <base>` and only adds application artifacts from the repository.
2. Use **BuildKit** semantics and cache mounts for package managers.
3. Enforce **determinism**: pin versions, lockfiles, and reproducible flags.
4. Keep runtime **small and non-root**; don’t drag toolchains into runtime unless explicitly required.
5. Provide **clear build commands** and a **validation checklist**.

**Inputs**
- Tech stack (e.g., Python/Node/Java/.NET), package manager (pip/npm/mvn/gradle/nuget), and list of “heavy” deps considered stable.
- Target platform(s) and final image registry tags.

**Output (Deliver all of this)**
1. `Dockerfile.base` with:
   - Pinned base image (e.g., `debian:12-slim`, `ubi9`, or distro per stack).
   - Optimized OS deps install with BuildKit cache mounts for `apt`, `apk`, `dnf` etc.
   - Installation of heavy language deps that change rarely (e.g., compilers, SDKs, core libs).
   - Cleanup of package caches and creation of non-root user.
2. `Dockerfile` (app) with:
   - `FROM <built-base>:<tag>`
   - Copy of lockfiles first (`requirements.txt`, `poetry.lock`, `package-lock.json`, `pom.xml`, etc.), dependency restore with cache mounts, then copy app sources.
   - Multi-stage if compilation is required (builder → runtime), but final still **consumes the external `base` image**.
   - `.dockerignore` tailored to exclude VCS, build outputs, caches.
3. **Build commands** for both images (plain Docker and `buildx`) including typical tags.
4. **Validation checklist** covering cache hits, image size, non-root, SBOM/labels, and repeat builds.
5. Short **rationale** explaining how the two-image split accelerates iterative builds.

**Authoring Rules**
- Place slow and rarely changing steps in `Dockerfile.base`. Place fast-changing app code in `Dockerfile`.
- Order instructions from least to most volatile to maximize cache hits.
- Use BuildKit cache mounts for package managers:
  - `RUN --mount=type=cache,target=/var/cache/apt ...`
  - `RUN --mount=type=cache,target=/root/.cache/pip ...`
  - `RUN --mount=type=cache,target=/root/.npm ...`
- Always clean indexes and temp files in the same `RUN` to keep layers slim.
- Use a non-root user, set `WORKDIR`, and add minimal `ENTRYPOINT`/`CMD` only in the final runtime stage.
- Pin base image digest and critical package versions; fail if lockfile missing.

**Template (structure; fill with stack-specific details, no placeholders left unresolved)**
- `Dockerfile.base`:
  - `# syntax=docker/dockerfile:1.7`
  - `FROM <distro>:<version>@<digest>`
  - OS deps install with cache mounts, version pins, cleanup.
  - Install heavy toolchains/runtimes/SDKs.
  - Create non-root user and set sane defaults.
- `Dockerfile`:
  - `# syntax=docker/dockerfile:1.7`
  - `FROM <your-base>:<tag> AS deps`
  - Copy lockfiles only; restore deps with cache mounts.
  - `FROM <your-base>:<tag> AS app`
  - Copy source; build/compile if needed; run tests if requested.
  - `FROM <runtime-minimal>` if splitting builder and runtime is beneficial; copy artifacts.
  - Labels, healthcheck (if applicable), non-root user, entrypoint.
  - For healthcheck API, always pick random port number, never leave defaulst (alike 8000).
- `.dockerignore` with typical patterns plus stack-specific ignores.

**Example Build Commands**
- Base:  
  `docker buildx build -f Dockerfile.base -t myorg/myapp-base:$(date +%Y%m%d) .`
- App:  
  `docker buildx build -f Dockerfile -t myorg/myapp:dev --build-arg BASE_TAG=$(date +%Y%m%d) .`
- Rebuild loop: change app code only → rebuild `Dockerfile` image; rebuild `Dockerfile.base` only when heavy deps change.

**Validation Checklist**
- Second build without changes to base completes significantly faster (verify cache hits in logs).
- Final image runs as non-root; toolchains absent from runtime unless required.
- Image size reduced versus monolithic baseline.
- `.dockerignore` effective; no VCS or build junk in layers.
- SBOM/labels present; base and app tags include version/date.

**Assumptions**
- BuildKit is enabled; if not, add instructions to enable it.
- If stack lacks lockfiles, require adding them or explicitly pin dependencies.

**Failure Policy**
- If any requirement cannot be met (missing lockfile, no non-root), emit explicit remediation steps and stop.
<!-- END: DOCKER_TWO_IMAGE_PROMPT -->

---
## DOCKER IMAGE LAYERING & SPLIT DOCKERFILES — MANDATORY RULES (Expert)

**Goal:** Keep rebuilds fast by never re‑downloading large, stable dependencies when app code changes. Achieve this by **splitting Dockerfiles** and designing **layer boundaries** that align with real change frequency.

### A. When to split a single Dockerfile
Split whenever a build pulls **large packages** (SDKs, compilers, CUDA stacks, browsers, heavy Python/R/Node libraries, system toolchains) or when the base layer change rate differs from app code. As a rule of thumb:
- If `apt/apk/pacman/yum` or `pip/npm/maven` pulls > 200 MB total, split.
- If native compilation or headless browsers are involved, split.
- If multiple language toolchains exist (e.g., .NET + Node + Python), split by toolchain.

### B. Canonical split and naming (separate Dockerfiles)
Use a **multi-image stack** built bottom‑up. Keep each Dockerfile small and purpose‑specific:
1) **Dockerfile.base** — Minimal OS base + core utilities only. Pin distro version and `apt` sources.
2) **Dockerfile.lang** — Language runtimes/SDKs (e.g., .NET SDK, Node, Python) with pinned versions.
3) **Dockerfile.deps** — Heavy third‑party libs (system + language package managers). Pin and lock (e.g., `requirements.txt`, `package-lock.json`, `poetry.lock`).
4) **Dockerfile.build** — Tooling for build/compile/transpile/test (e.g., `dotnet restore`, `npm ci`, `pip wheel`). Multi‑stage artifacts produced here.
5) **Dockerfile.runtime** — Final, minimal runtime image. Copy exact build outputs from `build` stage only.

> If your stack is smaller, collapse adjacent layers (e.g., merge `lang` + `deps`). If it’s larger, add `Dockerfile.browser`, `Dockerfile.cuda`, etc. The invariant: **stuff that rarely changes must be below stuff that changes often.**

### C. Image graph & dependency contract
- Each Dockerfile must declare an **image identity** and optional local dependencies via header comments:
  ```
  # IMAGE_NAME=myorg/app-lang
  # IMAGE_TAG=latest
  # IMAGE_DEPS=myorg/app-base,myorg/app-deps   # optional, for explicit ordering
  ```
- Prefer `FROM myorg/app-deps:latest` (or pinned tags) so the build order can be resolved automatically.

### D. Layer rules (to preserve cache)
- **Pin EVERYTHING that is heavy.** Use exact versions for OS packages and language deps. Example: `RUN apt-get update && apt-get install -y --no-install-recommends libxml2=2.9.* ...` (or distro‑specific pinning).
- **Separate dependency resolution from app code.**
  - Copy only manifest/lock files before install (e.g., `COPY package*.json` then `npm ci`, `COPY requirements.txt` then `pip install -r requirements.txt`).
  - Copy app source **after** dependency layers to avoid cache busting.
- **Multi‑stage builds**: compile in `build` stage, then `COPY --from=build` the exact outputs into `runtime`.
- **ARG boundary**: Treat `ARG` values as part of the public API. Changing a lower‑layer `ARG` invalidates all upper layers.
- **No volatile data** in heavy layers (do not `COPY .` or `RUN date` etc.).
- **Determinism**: disable network prompts; use `--no-install-recommends`, `npm ci`, `pip --no-cache-dir` only in build layers; freeze lockfiles.

### E. BuildKit & remote cache
- Always enable BuildKit: `DOCKER_BUILDKIT=1` with `docker buildx build`.
- Use **inline cache** and remote cache when registry is available:
  - `--cache-to=type=registry,ref=${REG}/myimg:cache,mode=max`
  - `--cache-from=type=registry,ref=${REG}/myimg:cache`
- For private registries, authenticate prior to build and prefer **content‑addressable** refs.

### F. Tagging, labels, provenance
- Name images predictably: `myorg/app-base`, `myorg/app-lang`, `myorg/app-deps`, `myorg/app-build`, `myorg/app-runtime`.
- Add OCI labels: `org.opencontainers.image.source`, `revision`, `created`, `licenses`, `base.name`.
- Tag by stack versions, e.g., `:ubuntu22.04-dotnet8-node22-py3.11` for `lang`, and plain `:latest` for runtime if desired.

### G. Rebuild policy
- **Always build all images** in dependency order (fast due to cache). CI should fail if any lower image is missing.
- Rebuild triggers:
  - Change in lockfiles → rebuild `deps` and above.
  - Change in source → rebuild `build` + `runtime` only.
  - Change in SDK/base → rebuild everything (rare).

### H. Repository layout (recommended)
```
docker/
  base/Dockerfile.base
  lang/Dockerfile.lang
  deps/Dockerfile.deps
  build/Dockerfile.build
  runtime/Dockerfile.runtime
scripts/
  _buildDocker.sh          # builds all images in correct order
```

### I. Quality gates
- Image size budgets per tier (fail if exceeded).
- `trivy` scan on each built image; block critical vulns.
- `hadolint` on all Dockerfiles; block high‑severity issues.
- Reproducible builds: pin tz, locales; purge caches; verify SBOM (e.g., `syft`, `bom`).

### K. ## Rule: Pre-bake external dependencies into a Docker base image to avoid re-downloading on source changes

### Intent
All third-party libraries, packages, artifacts, runtimes, and tooling downloaded from the Internet that are **not part of the solution’s source code** (i.e., not compiled from the repository during the build) **MUST** be placed into a dedicated **Docker base image**.  
As a result, **changes in the solution’s source code MUST NOT trigger re-downloading** those external artifacts from the network. Only the final application image (containing the updated source/build output) should change.

### Definitions
- **Source code (solution code):** repository-owned code that is compiled/built during the build process.
- **External artifacts:** OS packages, language runtimes, package manager caches, browser binaries (e.g., Playwright), CLIs, SDKs, build tools, fonts, CA bundles, and any other downloaded binaries not authored in the repo.
- **Base image:** a versioned Docker image that contains external artifacts and remains stable across frequent application code changes.
- **Application image:** the image layer(s) that contain the solution’s code and build outputs.

### Requirements (non-negotiable)
1. **Create a dedicated base image** (e.g., `org/app-base:<version>`) that contains all external artifacts required for:
   - building (if you use a build container),
   - testing (e.g., Playwright browsers and OS deps),
   - running (runtime dependencies).
2. **Application images must be built FROM the base image** and must not re-install the same third-party artifacts on every build.
3. **Source code changes must not invalidate dependency layers.** Dockerfile steps that download external artifacts must occur **before** copying the repository source into the image.
4. **No “curl | bash” ambiguity:** all external downloads must be pinned to known versions, checksummed where possible, and reproducible.

### Best practices (strongly recommended)
#### A) Layering and build structure
- Use **multi-stage builds**:
  - `base` stage: OS deps + language toolchains + pinned third-party tools.
  - `build` stage: compile the application using the base.
  - `runtime` stage: minimal runtime output (copy built artifacts only).
- Keep dependency installation in stable layers:
  - Copy only lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `*.csproj`, `packages.lock.json`, `poetry.lock`, `requirements.txt`) before installing dependencies.
  - Copy the rest of source code only after dependency install layers.

#### B) Version pinning and integrity
- Pin versions for:
  - OS packages (as much as the distro allows),
  - language runtimes (Node/.NET/Python/Java),
  - package manager versions (npm/pnpm/yarn),
  - external CLIs and browsers (Playwright).
- Verify integrity:
  - prefer official package repositories,
  - use checksums/signatures for downloaded binaries when available,
  - store version metadata in labels (e.g., OCI labels).

#### C) Caching without corruption
- Prefer Docker BuildKit cache mounts where supported:
  - cache package managers (`npm`, `pnpm`, `pip`, `nuget`) in a controlled way.
- Avoid “dirty” caches that make builds non-deterministic:
  - use lockfiles and immutable installs (`npm ci`, `pnpm --frozen-lockfile`).

#### D) Network minimization and offline-friendly builds
- The base image can be built with network access, but **application image builds should be able to run with minimal/no network**, especially in CI:
  - dependencies and tools already present in base,
  - only fetch what is truly unavoidable (and document why).
- For high assurance environments:
  - use internal artifact registries (e.g., Nexus/Artifactory),
  - mirror OS repos and package registries,
  - enable SLSA-style provenance where feasible.

#### E) Security and supply chain hygiene
- Run as non-root in runtime images where possible.
- Keep base images patched and versioned:
  - treat base image updates as a controlled change (security updates, tool updates).
- Record SBOM for base and application images (recommended).
- Avoid embedding secrets:
  - never bake credentials into the base image,
  - use build-time secrets properly (BuildKit secrets, CI secret stores).

#### F) Practical examples of what belongs in the base image
- Playwright: browsers + OS dependencies.
- CA certificates, timezone data, fonts.
- Language runtime/toolchain: Node, .NET SDK, Python + pip tooling.
- System utilities required by tests (curl/jq) or app runtime.
- Corporate root certificates (if needed), but managed securely.

### Acceptance criteria
- Rebuilding after a source-only change **does not perform** any network downloads for toolchains/browsers/system deps already in the base image.
- CI logs confirm that dependency layers are reused (cache hits) and builds are faster and consistent.
- Base image is versioned and can be updated independently from the application code.

### L. Non‑negotiables
- No `latest` in **FROM** unless it points to **your** controlled base in this stack.
- No copying of package managers’ caches into the runtime.
- No secrets in build args; use BuildKit secrets or CI‑injected mounts.
- Keep runtime non‑root, drop caps, read‑only FS where possible.
- No ARM64 architecture or builds! Only Linux x64 (AMD64) builds and libraries are acceptable!
- NEVER, under any cisrumstances, modify or delete file /etc/env/bot_env. You can only use it, read it, no modification!
- After finishing development work and tests (local), delete all the containers and images, that has been built or used during development phase. So that local docker environment is clean.
- Images: pin versions; examples: python:3.11-slim, debian:12-slim, ubuntu:22.04. Always build with --platform=linux/amd64.
- Multi-stage builds; non-root; minimal OS deps; HEALTHCHECK; /healthz liveness + /readyz readiness.
- Env management: non-sensitive config via env file mounted as volume and sourced in entrypoint; secrets via K8s Secrets.
- Always perform build and compile operations (within Dockerfiles) as root, set propper permissions for objects, set application user at the very end
- Always completly check the whole solution whether it compiles properly and works properly. Check the status and logs of all components as well as total, complete system. Destination platform is Linux/x64.
- Always check if scripts use exact and propper objects (scripts, files, commands). Perform corrections if needed and check them before finishing work.
- Always assume, that if solution uses database (postgresql), it always already exists, connection strings, usernames, passwords and dabatabse names are within environment variables. Never place postgresql as new instance within docker compose or similar.
- Always assume, that if errors detected and reported, you should NOT seek for them locally, as complete solutions and applications are run on remote, Linux/x64 server. Instead of halucinations and local checks, ask for logs, printing out complete command line commands.
- Always use local solution component images, and only use remote images (hub.docker.com, other feeds) if the are base images (like python, ubuntu, debian, alpine).
- Before build of docker images, check which versions are required from remote feed (hub.docker.com, other like quay.io) and reort error if required images are not available within remote feed.
