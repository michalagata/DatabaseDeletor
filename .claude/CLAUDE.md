# CLAUDE.md — Global Claude Code Instructions

> **Scope:** This file is the single source of truth for Claude Code behavior across all repositories.
> **Location:** `~/.claude/CLAUDE.md` (user-global) or `<repo>/.claude/CLAUDE.md` (per-project).

---

## 🧠 MEMORY SYSTEM (HIGHEST PRIORITY — READ FIRST)

Claude Code operates with **persistent file-based memory** stored in `<repo>/.memory/`.
Every single step in every session MUST follow the **READ → ACT → WRITE** memory cycle.
Violating this cycle means losing context — which is a critical failure.

### Memory File Structure

```
<repo>/.memory/
├── STATE.md          # Short-term: current task, last action, next step, blockers
├── CONTEXT.md        # Long-term: architecture decisions, tech stack, key patterns
├── HISTORY.md        # Append-only log: timestamped record of ALL actions taken
└── COMPACT.md        # Compaction snapshot: full state saved before each /compact
```

### The READ → ACT → WRITE Cycle (MANDATORY for EVERY step)

Every single interaction — no exceptions — follows this three-phase cycle:

#### Phase 1: READ (before doing anything)

```
┌─────────────────────────────────────────────────────┐
│  BEFORE any action, read ALL memory files:          │
│                                                     │
│  1. Read .memory/STATE.md   → current task state    │
│  2. Read .memory/CONTEXT.md → architecture context  │
│  3. Read .memory/HISTORY.md → what happened before  │
│                                                     │
│  If .memory/ directory does not exist → create it.  │
│  If any file does not exist → create it empty.      │
│  NEVER skip this phase.                             │
└─────────────────────────────────────────────────────┘
```

**After reading, internally confirm:**
- What is the current task and its status?
- What decisions have already been made?
- What was the last action performed?
- Are there any blockers or `NEEDS INPUT` items?

#### Phase 2: ACT (do the work)

Perform the requested task. During this phase:
- Reference loaded memory to avoid repeating work or contradicting prior decisions.
- If a decision conflicts with something in CONTEXT.md, flag it explicitly to the user.
- Track every file touched, every decision made, every error encountered.

#### Phase 3: WRITE (after completing the action)

```
┌─────────────────────────────────────────────────────┐
│  AFTER every action, update ALL relevant files:     │
│                                                     │
│  1. UPDATE .memory/STATE.md   → new current state   │
│  2. UPDATE .memory/CONTEXT.md → if decisions changed│
│  3. APPEND .memory/HISTORY.md → log what was done   │
│                                                     │
│  NEVER skip this phase. NEVER defer to "later".     │
│  Memory writes happen IMMEDIATELY after action.     │
└─────────────────────────────────────────────────────┘
```

---

### Memory File Formats

#### `.memory/STATE.md` — Short-Term Memory (overwritten each step)

```markdown
# Current State

## Active Task
<one-line description of what we're working on>

## Status
<not-started | in-progress | blocked | completed>

## Completion
<percentage or step X of Y>

## Last Action
<what was just done, with affected file paths>

## Next Step
<what should happen next>

## Files Modified This Session
- `path/to/file1.ext` — <what changed>
- `path/to/file2.ext` — <what changed>

## Open Decisions
- <any pending architectural/implementation choices>

## Blockers (NEEDS INPUT)
- <anything requiring user input before proceeding>

## Git State
- Branch: `<branch-name>`
- Last commit: `<hash> <message>`
- Uncommitted changes: <yes/no, list if yes>

## Loaded Rules
- <list of .github/rules/*.md files currently in effect>

## User Preferences (This Session)
- <any explicit instructions or preferences from the user>
```

#### `.memory/CONTEXT.md` — Long-Term Memory (updated only on significant decisions)

```markdown
# Project Context

## Tech Stack
- <language, framework, versions>

## Architecture
- <pattern: Clean Architecture / hexagonal / etc.>
- <key boundaries and layers>

## Key Decisions (ADR-style)
### Decision: <title>
- **Date:** <YYYY-MM-DD>
- **Context:** <why this came up>
- **Decision:** <what was chosen>
- **Alternatives considered:** <what was rejected and why>
- **Consequences:** <impact>

## Conventions
- <naming, structure, patterns used in this repo>

## Integration Points
- <external services, APIs, databases>

## Known Constraints
- <performance limits, compliance requirements, tech debt>
```

#### `.memory/HISTORY.md` — Action Log (append-only, never overwrite)

```markdown
# Session History

## [YYYY-MM-DD HH:MM] Session Start
- Task: <description>
- Rules loaded: <list>

## [YYYY-MM-DD HH:MM] Step 1: <action title>
- Action: <what was done>
- Files: <paths affected>
- Result: <success/failure + details>
- Decision: <if any decision was made, record it>

## [YYYY-MM-DD HH:MM] Step 2: <action title>
...
```

#### `.memory/COMPACT.md` — Pre-Compaction Snapshot (overwritten before each compact)

Written **immediately before** any `/compact` or auto-compact triggers. This is the safety net.

```markdown
# Pre-Compaction Snapshot — <YYYY-MM-DD HH:MM>

## Full STATE.md at time of compaction
<entire contents of STATE.md>

## Full CONTEXT.md at time of compaction
<entire contents of CONTEXT.md>

## Recent HISTORY.md entries (last 20 entries)
<last 20 entries from HISTORY.md>

## Compaction reason
<auto-compact at X% | manual /compact | user requested>
```

---

### Memory Lifecycle for Every Session Type

#### New Session (`claude`)
```
1. Check .memory/ exists          → create if missing
2. READ  STATE.md, CONTEXT.md     → understand current project state
3. READ  HISTORY.md               → understand what happened in prior sessions
4. Greet user with awareness:     "Resuming from: <last action>. Next step: <X>"
5. Proceed with READ → ACT → WRITE for each step
```

#### Resumed Session (`claude -c`)
```
1. READ all memory files          → restore full context
2. Check if compaction occurred   → if yes, READ COMPACT.md for lost details
3. Confirm understanding:         "After compaction, I've restored: <summary>"
4. Proceed with READ → ACT → WRITE for each step
```

#### Before Compaction (`/compact` or auto-compact)
```
1. WRITE full snapshot to COMPACT.md
2. WRITE final STATE.md with complete current state
3. APPEND to HISTORY.md: "[timestamp] COMPACTION — reason: <reason>"
4. Then allow compaction to proceed
5. Compact summary MUST reference: "Full state saved in .memory/COMPACT.md"
```

#### After Compaction (first step post-compact)
```
1. READ COMPACT.md                → recover full pre-compaction state
2. READ STATE.md                  → verify it survived compaction
3. READ HISTORY.md                → verify action log is intact
4. If any data is missing         → restore from COMPACT.md
5. Confirm: "Context restored from .memory/. Continuing with: <task>"
```

---

### Context Monitoring & Proactive Compaction

- At **50% context usage**: Inform the user, suggest reviewing `.memory/STATE.md`.
- At **60% context usage**: Strongly recommend running `/compact`. Offer to do a pre-compact snapshot.
- At **70% context usage**: Write COMPACT.md immediately as a precaution.
- **Before any auto-compact fires**: ALWAYS write COMPACT.md first. This is non-negotiable.

### Compact Command Template

When the user runs `/compact` without arguments, use this implicit instruction:

```
Preserve: task progress, all file changes with paths, decisions and rationale,
errors and resolutions, git branch and commits, loaded rule files, user preferences,
blocked items. Full state is persisted in .memory/COMPACT.md.
```

---

## 0) ABSOLUTE RULES (NON-NEGOTIABLE)

> **Memory hook:** Before checking these rules, `.memory/STATE.md` must already be loaded (Phase 1: READ).

1. **Zero hallucinations.**
   - Never invent APIs, CLI flags, config keys, file paths, base images, or library behavior.
   - If something is uncertain, create an **ASSUMPTIONS** section and proceed with the safest backward-compatible option.
   - When unsure, say `NEEDS INPUT` and log the blocker to `.memory/STATE.md` → Blockers section.

2. **No behavior regression.**
   - Preserve existing functionality, public APIs, and execution order unless explicitly instructed otherwise.
   - If a breaking change is unavoidable, provide an adapter layer + SemVer plan + migration notes.
   - Log the breaking change decision to `.memory/CONTEXT.md` → Key Decisions.

3. **OSS & Self-Hosted first.**
   - Prefer **free, open-source** components (OSI-approved or clearly open-source).
   - Avoid external SaaS dependencies for inference/vector DB/registries/CI/CD/secrets unless explicitly approved.

4. **Security by default.**
   - Never hardcode secrets. Never print secrets. Never commit `.env`, tokens, or private keys.
   - Apply least privilege, safe defaults, strict input validation, and secure-by-design patterns.

5. **English-only engineering artifacts.**
   - Code comments, logs, exceptions, docs, UI strings, commit messages: **English only**.
   - Conversations with the user may be in any language the user prefers.

---

## 1) OUTPUT CONTRACT (Response Structure)

> **Memory hook:** After producing a response with code, immediately execute Phase 3: WRITE.

When answering with code or changes, use this structure (adapt if the user asks for a specific format):

1. **TL;DR** — 1–3 bullets summarizing the change.
2. **ASSUMPTIONS** — Only if needed; list anything uncertain.
3. **PLAN** — Short, ordered steps of what will be done.
4. **CHANGES** — Per file: what changed and why.
5. **PATCH / CODE** — Complete, runnable snippets; prefer unified diffs when practical.
6. **TEST PLAN** — How to verify, including exact commands.
7. **RISK & ROLLBACK** — What could break and how to revert.
8. **DOCS / CHANGELOG** — What documentation needs updating.
9. **MEMORY UPDATE** — Proposed updates to `.memory/STATE.md` and `.memory/HISTORY.md`.
10. **Hallucination Check:** `PASSED` or `NEEDS INPUT`

---

## 2) ARCHITECTURE & DESIGN STANDARDS

> **Memory hook:** Before proposing architecture changes, READ `.memory/CONTEXT.md` to check for prior decisions. After making a decision, WRITE it to `.memory/CONTEXT.md` → Key Decisions.

### 2.1 Architecture Discipline
- Prefer **Clean Architecture / modular boundaries**: clear separation of domain, application, infrastructure, and delivery layers.
- Keep dependencies directed inward; prevent cyclic dependencies.
- Use **ADRs** (Architecture Decision Records) for significant decisions:
  Context → Decision → Alternatives → Consequences → Migration/Rollback.
- **Every ADR must also be recorded in `.memory/CONTEXT.md`.**

### 2.2 NFRs and Quality Gates
- Maintain a lightweight **NFR matrix (ISO/IEC 25010)** for critical services:
  characteristic → metric → target → verification method.
- Any design must address: reliability, security, performance, maintainability, observability, cost.

### 2.3 Data & Integration Safety
- No silent data loss.
- Prefer idempotent operations, outbox/inbox patterns, and explicit retries with backoff.
- Validate all external inputs (API, queues, files) with strict schemas.

---

## 3) CODING STANDARDS (Language-Specific)

### 3.1 .NET (default backend)
- Target **.NET 8** unless the repo states otherwise.
- Prefer explicit DI registrations, options pattern, structured logging.
- Use cancellation tokens for I/O and long-running operations.
- Avoid sync-over-async; propagate timeouts and retries with clear policies.
- Favor predictable error models (problem details / consistent error envelopes).

### 3.2 Angular / TypeScript (default frontend)
- Use latest Angular patterns used in the repo (standalone components if applicable).
- Keep strict TS settings, strong typing, and predictable state management.
- Prefer deterministic, testable logic; avoid side effects in view layers.

### 3.3 Python (when present)
- Use typing, Pydantic (if used in repo), `pytest`, and sane linting (ruff/flake8/mypy depending on repo).
- Prefer streaming and chunked processing for large payloads.
- Avoid hidden global state; keep functions testable.

### 3.4 General Refactoring Standards
- **Measure first** (profiling/benchmarks) before "optimizing".
- Remove high-interest technical debt (dead code, duplication, needless abstractions).
- Keep changes minimal but complete. No drive-by rewrites.

---

## 4) TESTING POLICY (Required)

> **Memory hook:** After adding/updating tests, log to `.memory/HISTORY.md` which test files were touched and whether they pass.

- If tests are missing for changed logic, **add them**.
- Target **≥ 80% coverage** for touched modules where feasible.
- Use:
  - **Unit tests** for logic.
  - **Integration tests** for IO boundaries.
  - **Contract tests** for service interfaces (when applicable).
  - **Smoke tests** for startup + critical routes.
- Include the exact commands to run tests locally and in CI.

---

## 5) DEVOPS, CONTAINERS & KUBERNETES

### 5.1 Docker Requirements
- Multi-stage Dockerfiles, pinned base images, minimal final images.
- Run as **non-root**. Prefer read-only filesystem where feasible.
- Include a **startup self-check** (fail fast with actionable logs).
- Default target platform: **linux/amd64** (unless explicitly asked otherwise).
- Never bake secrets into images.

### 5.2 Kubernetes Requirements
- Provide readiness/liveness probes, resource requests/limits, and secure defaults.
- Prefer GitOps-friendly manifests; include rollback instructions.
- Use NetworkPolicies (default-deny) when feasible.

---

## 6) SECURITY & COMPLIANCE GUARDRAILS

- Threat model for non-trivial changes (STRIDE/PASTA), with mitigations.
- Map critical controls to OWASP guidance (ASVS where applicable).
- Keep dependencies current and compatible; note CVEs and remediation steps.
- Prefer SBOM + image/dependency scanning in CI where the repo supports it.

---

## 7) DOCUMENTATION & CHANGE MANAGEMENT

> **Memory hook:** Every doc update must be logged to `.memory/HISTORY.md`.

- Update docs **whenever behavior, config, or interfaces change**.
- Maintain **CHANGELOG.md** entries for user-visible changes.
- Provide migration + rollback notes for schema changes or breaking behavior.

---

## 8) MULTI-FILE WORKFLOW

> **Memory hook:** Before starting multi-file work, READ `.memory/STATE.md` → Files Modified to avoid conflicts. After completing, WRITE the full working set to STATE.md.

When making multi-file changes:
1. **READ** `.memory/STATE.md` — check for files already in-progress.
2. List the **working set** (files you will touch).
3. Make changes in coherent commits: one intent per commit.
4. After edits, run and report: format/lint → tests → build → smoke/startup checks.
5. **WRITE** all touched files to `.memory/STATE.md` → Files Modified section.
6. **APPEND** to `.memory/HISTORY.md` — one entry per logical change.

---

## 9) INCOMPLETE DETAILS ("Just Do It" Mode)

When the user asks to proceed with incomplete details, do not stall. Proceed with:
- Minimal safe defaults.
- Explicit assumptions (in an **ASSUMPTIONS** section).
- Reversible changes.
- A clear rollback plan.
- **Log all assumptions to `.memory/STATE.md` → Open Decisions.**

---

## 10) WORKFLOW EXECUTION

> **Memory hook:** Before executing a workflow, READ `.memory/STATE.md` to check if a workflow is already in progress. After execution, WRITE result to both STATE.md and HISTORY.md.

### 10.1 Prompt-Based Workflows
If the user asks to "Run workflow X" or "Execute prompt Y":
1. **READ** `.memory/STATE.md` — verify no conflicting task is in progress.
2. Check `.github/prompts/Y.prompt.md` (generated from `.memory/workflows.json`).
3. Follow the steps defined in that markdown file rigorously.
4. **WRITE** workflow result to `.memory/STATE.md` and `.memory/HISTORY.md`.

### 10.2 Operating Rules
- If the question touches the whole repo, use workspace/codebase context.
- Never place secrets into repo files or chat. Use env vars/placeholders.

---

## 11) DYNAMIC RULE INDEX (MANDATORY — AUTO-LOAD)

> **Memory hook:** After loading rules, record which files were loaded in `.memory/STATE.md` → Loaded Rules. This ensures rules survive compaction.

### Rule Loading Protocol

**At the start of every session and before every task**, Claude Code MUST:

1. **READ** `.memory/STATE.md` → Loaded Rules — check if rules are already loaded for this session.
2. **Check for `.github/rules/` directory** in the current repository root.
3. **If `.github/rules/` exists:** Scan for all `*.md` files, identify which rule files are relevant to the current task domain, read them, and strictly follow their content.
4. **If `.github/rules/` does NOT exist:** Fall back to the shared rules repository:
   ```
   /Users/anubis/REPOSITORY/conf/WorkStation/NewRepo/.github/rules/
   ```
   Read the applicable rule files from that location instead.
5. **Confirm compliance and persist:** After loading rules, output confirmation AND write to memory:
   ```
   ✅ Rules loaded from: <path>
   Active rule files: <list of loaded .md filenames>
   ```
   → **WRITE** the list to `.memory/STATE.md` → Loaded Rules.
6. **APPEND** to `.memory/HISTORY.md`: `[timestamp] Rules loaded: <list> from <path>`.

### Domain-to-Rule Mapping

Identify which rule set applies based on the user's request domain, then read and follow the corresponding file:

| Domain | Rule File |
|--------|-----------|
| General quality (always active) | `general.md` |
| AI / LLM | `ai.md` |
| Android | `android.md` |
| Angular | `angular.md` |
| Architecture (DDD, hexagonal, CQRS, EDA) | `architecture.md` |
| Bash / POSIX shell | `bash.md` |
| Code review (concise) | `codereview-short.md` |
| Code review (comprehensive) | `codereview.md` |
| Database | `database.md` |
| DevOps / SRE / Platform | `devops.md` |
| Docker | `docker.md` |
| .NET | `dotnet.md` |
| End-to-end system design | `gen-devel.md` |
| Go | `go.md` |
| iOS | `ios.md` |
| Java / Spring Boot | `java.md` |
| Kubernetes | `k8s.md` |
| PowerShell | `powershell.md` |
| Python | `python.md` |
| React / TypeScript | `react.md` |
| Refactoring / Modernization | `refactoring.md` |
| Rust | `rust.md` |
| Solution Architecture | `solution-architect.md` |
| Solution Creation | `solution-creator.md` |
| WCAG / Accessibility | `wcag.md` |
| Windows Batch scripts | `windows-bat.md` |
| Web Frontend (SPA/MPA/SSR) | `www.md` |

### Numbered Module Files (Architecture & Engineering)

These modules form the unified master engineering prompt and should be loaded when relevant:

| Module | File |
|--------|------|
| Operating Principles | `01_operating_principles.md` |
| Global Best Practices | `02_global_best_practices.md` |
| Architecture Patterns | `03_architecture_patterns.md` |
| AI/LLM Standards | `04_ai_llm_standards.md` |
| OSS Reuse Workflow | `05_oss_reuse_workflow.md` |
| Output Structure | `06_output_structure.md` |
| Quality Gates | `07_quality_gates.md` |
| Contracts for APIs & Events | `08_contracts_api_events.md` |
| CI/CD & Observability | `09_cicd_observability.md` |
| Templates & Commits | `10_templates_and_commits.md` |
| Unified Master Prompt | `unified_master_prompt.md` |
| Universal Expert Refactor | `universal_expert_refactor_prompt.md` |

> **INSTRUCTION:** Identify which rule set applies, read the file from `.github/rules/` (or the fallback path), and strictly follow its content. Multiple rule files may apply simultaneously — load all relevant ones.

---

## 12) FINAL CHECKLIST (End of Every Response with Code)

This checklist is **mandatory**. Do not skip any item.

```
┌─────────────────────────────────────────────────────────────────┐
│  END-OF-STEP CHECKLIST                                         │
│                                                                 │
│  □ Phase 3: WRITE completed?                                   │
│    ├── .memory/STATE.md    updated with current state?          │
│    ├── .memory/HISTORY.md  appended with action log entry?      │
│    └── .memory/CONTEXT.md  updated if decisions changed?        │
│                                                                 │
│  □ Hallucination Check: PASSED / NEEDS INPUT                   │
│  □ Tests added/updated for changed logic?                      │
│  □ No secrets exposed?                                         │
│  □ Relevant .github/rules/*.md loaded and followed?            │
│  □ Rollback plan provided for non-trivial changes?             │
│  □ MEMORY UPDATE section included in response?                 │
│                                                                 │
│  If ANY item is unchecked → fix it before finishing response.   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 QUICK REFERENCE: Memory Cycle Diagram

```
  ┌──────────────────────────────────────────────────────────┐
  │                    EVERY INTERACTION                      │
  │                                                          │
  │  ┌──────────┐     ┌──────────┐     ┌──────────┐         │
  │  │  1. READ  │────▶│  2. ACT  │────▶│ 3. WRITE │         │
  │  └──────────┘     └──────────┘     └──────────┘         │
  │       │                                   │              │
  │       ▼                                   ▼              │
  │  Load from:                         Save to:             │
  │  • STATE.md                         • STATE.md (update)  │
  │  • CONTEXT.md                       • CONTEXT.md (if     │
  │  • HISTORY.md                         decisions changed) │
  │                                     • HISTORY.md (append)│
  │                                                          │
  │  ┌─────────────────────────────────────────────┐         │
  │  │  BEFORE /compact:                           │         │
  │  │  • Write COMPACT.md (full snapshot)          │         │
  │  │  • Update STATE.md (final state)             │         │
  │  │  • Append HISTORY.md (compaction entry)      │         │
  │  └─────────────────────────────────────────────┘         │
  │                                                          │
  │  ┌─────────────────────────────────────────────┐         │
  │  │  AFTER /compact or session resume:          │         │
  │  │  • Read COMPACT.md → restore lost context    │         │
  │  │  • Read STATE.md   → verify state survived   │         │
  │  │  • Read HISTORY.md → verify log is intact    │         │
  │  │  • Confirm: "Context restored. Continuing."  │         │
  │  └─────────────────────────────────────────────┘         │
  └──────────────────────────────────────────────────────────┘
```
