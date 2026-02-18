#!/bin/bash

# ==============================================================================
# VS Code "Cursor Brain" & UI Setup
# ==============================================================================
# This script configures VS Code to look and behave like Cursor.
# It merges user-provided configs with Cursor-like UI settings and
# sets up the necessary file structure for context memory.
# ==============================================================================

VSCODE_DIR=".vscode"
GITHUB_DIR=".github"
DOCS_AI_DIR="docs/ai"
TOOLS_DIR="tools"

mkdir -p "$VSCODE_DIR" "$GITHUB_DIR" "$DOCS_AI_DIR" "$TOOLS_DIR"

echo ">> Setting up Cursor-like infrastructure..."

# ------------------------------------------------------------------------------
# 1. EXTENSIONS.JSON
# ------------------------------------------------------------------------------
# Combines user's recommendations with run-on-save
cat > "$VSCODE_DIR/extensions.json" <<EOF
{
  "recommendations": [
    "emeraldwalk.runonsave",
    "github.copilot",
    "github.copilot-chat"
  ]
}
EOF
echo "   [OK] extensions.json updated."

# ------------------------------------------------------------------------------
# 2. SETTINGS.JSON
# ------------------------------------------------------------------------------
# Merges the user's run-on-save logic with Cursor Visuals (Minimal UI)
cat > "$VSCODE_DIR/settings.json" <<EOF
{
    "workbench.colorTheme": "Default Dark Modern",
    "editor.fontFamily": "SF Mono, Menlo, Monaco, 'Courier New', monospace",
    "editor.fontSize": 13,
    "editor.lineHeight": 20,
    "editor.minimap.enabled": false,
    "editor.stickyScroll.enabled": true,
    "window.commandCenter": false,
    
    "workbench.activityBar.location": "hidden",
    "workbench.statusBar.visible": true,
    "workbench.sideBar.location": "left",
    "workbench.editor.showTabs": "multiple",
    
    "chat.editor.fontFamily": "SF Mono, Menlo, monospace",
    "github.copilot.editor.enableAutoCompletions": true,
    
    "workbench.colorCustomizations": {
        "editor.background": "#121212",
        "sideBar.background": "#121212",
        "activityBar.background": "#121212",
        "statusBar.background": "#121212",
        "titleBar.activeBackground": "#121212",
        "editorGroupHeader.tabsBackground": "#121212",
        "tab.activeBackground": "#121212",
        "tab.inactiveBackground": "#121212",
        "tab.border": "#121212",
        "editorLineNumber.activeForeground": "#ffffff",
        "editorLineNumber.foreground": "#444444"
    },

    "github.copilot.chat.codeGeneration.useInstructionFiles": true,

    "emeraldwalk.runonsave": {
        "commands": [
            {
                "match": ".*",
                "cmd": "bash tools/update_context.sh"
            },
            {
                "match": "docs/ai/workflows.json",
                "cmd": "python3 tools/gen_prompts.py"
            }
        ]
    }
}
EOF
echo "   [OK] settings.json updated (Visuals + Logic)."

# ------------------------------------------------------------------------------
# 3. COPILOT-INSTRUCTIONS.MD
# ------------------------------------------------------------------------------
# We append the "Cursor Interaction Protocol" to your existing instructions.
# This ensures Copilot knows HOW to use the files defined in settings.

INSTRUCTIONS_FILE="$GITHUB_DIR/copilot-instructions.md"

# Write the user's existing base content first (from your prompt)
cat > "$INSTRUCTIONS_FILE" <<EOF
# GitHub Copilot Instructions (Repo-Wide)

> **Purpose:** Make Copilot behave like a disciplined “Cursor-grade” engineering assistant: consistent, multi-file capable, test-first, security-aware, zero-hallucination, and compatible with an OSS/on‑prem stack.

## 0) Absolute Rules (Non‑Negotiable)

1. **Zero hallucinations.**
   - Never invent APIs, CLI flags, config keys, file paths, base images, or library behavior.
   - If something is uncertain, create an **ASSUMPTIONS** section and proceed with the safest backward‑compatible option.

2. **No behavior regression.**
   - Preserve existing functionality, public APIs, and execution order unless explicitly instructed otherwise.
   - If a breaking change is unavoidable, provide an adapter layer + SemVer plan + migration notes.

3. **OSS & Self‑Hosted first.**
   - Prefer **free, open‑source** components (OSI-approved or clearly open-source).
   - Avoid external SaaS dependencies for inference/vector DB/registries/CI/CD/secrets unless explicitly approved.

4. **Security by default.**
   - Never hardcode secrets. Never print secrets. Never commit \`.env\`, tokens, or private keys.
   - Apply least privilege, safe defaults, strict input validation, and secure-by-design patterns.

5. **English-only engineering artifacts.**
   - Code comments, logs, exceptions, docs, UI strings, commit messages: **English only**.

---

## 1) How You Should Respond (Output Contract)

When answering with code or changes, use this structure (adapt if the user asks for a specific format):

1. **TL;DR** (1–3 bullets)
2. **ASSUMPTIONS** (only if needed)
3. **PLAN** (short, ordered steps)
4. **CHANGES** (per file, what and why)
5. **PATCH / CODE** (complete, runnable snippets; prefer unified diffs when practical)
6. **TEST PLAN** (how to verify, including commands)
7. **RISK & ROLLBACK** (what could break and how to revert)
8. **DOCS / CHANGELOG** (what to update)
9. **Hallucination Check:** \`PASSED\` or \`NEEDS INPUT\`

If you can’t be certain, say \`NEEDS INPUT\` and list exactly what input is missing.

---

## 2) Repo Architecture & Design Standards

### 2.1 Architecture discipline
- Prefer **Clean Architecture / modular boundaries**: clear separation of domain, application, infrastructure, and delivery layers.
- Keep dependencies directed inward; prevent cyclic dependencies.
- Use **ADRs** (Architecture Decision Records) for significant decisions:
  - Context → Decision → Alternatives → Consequences → Migration/Rollback.

### 2.2 NFRs and quality gates
- Maintain a lightweight **NFR matrix (ISO/IEC 25010)** for critical services:
  - characteristic → metric → target → verification method.
- Any design must address: reliability, security, performance, maintainability, observability, cost.

### 2.3 Data & integration safety
- No silent data loss.
- Prefer idempotent operations, outbox/inbox patterns, and explicit retries with backoff.
- Validate all external inputs (API, queues, files) with strict schemas.

---

## 3) Coding Standards (Language-Specific)

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
- Use typing, Pydantic (if used in repo), \`pytest\`, and sane linting (ruff/flake8/mypy depending on repo).
- Prefer streaming and chunked processing for large payloads.
- Avoid hidden global state; keep functions testable.

### 3.4 General refactoring standards
- **Measure first** (profiling/benchmarks) before “optimizing”.
- Remove high-interest technical debt (dead code, duplication, needless abstractions).
- Keep changes minimal but complete. No drive-by rewrites.

---

## 4) Testing Policy (Required)

- If tests are missing for changed logic, add them.
- Target **≥ 80% coverage** for touched modules where feasible.
- Use:
  - unit tests for logic
  - integration tests for IO boundaries
  - contract tests for service interfaces (when applicable)
  - smoke tests for startup + critical routes
- Include the exact commands to run tests locally/CI.

---

## 5) DevOps, Containers, and Kubernetes (When Relevant)

### 5.1 Docker requirements
- Multi-stage Dockerfiles, pinned base images, minimal final images.
- Run as **non-root**. Prefer read-only filesystem where feasible.
- Include a **startup self-check** (fail fast with actionable logs).
- Default target platform: **linux/amd64** (unless explicitly asked otherwise).
- Never bake secrets into images.

### 5.2 Kubernetes requirements
- Provide readiness/liveness, resource requests/limits, and secure defaults.
- Prefer GitOps-friendly manifests; include rollback instructions.
- Use NetworkPolicies (default-deny) when feasible.

---

## 6) Security & Compliance Guardrails

- Threat model for non-trivial changes (STRIDE/PASTA), with mitigations.
- Map critical controls to OWASP guidance (ASVS where applicable).
- Keep dependencies current and compatible; note CVEs and remediation steps.
- Prefer SBOM + image/dependency scanning in CI where the repo supports it.

---

## 7) Documentation & Change Management

- Update docs **whenever behavior, config, or interfaces change**.
- Maintain **CHANGELOG.md** entries for user-visible changes.
- Provide migration + rollback notes for schema changes or breaking behavior.

---

## 8) “Cursor-like” Workflow Tips (How to Make Edits Actually Work)

When making multi-file changes:
- Start by listing the **working set** (files you will touch).
- Make changes in coherent commits: one intent per commit.
- After edits, run and report:
  - format/lint
  - tests
  - build
  - smoke/startup checks

---

## 9) If the user asks for “just do it” with incomplete details

Do not stall. Proceed with:
- minimal safe defaults,
- explicit assumptions,
- reversible changes,
- a clear rollback plan.

---

# Copilot Repository Instructions (Memory Harness)

You are working inside a repository that maintains *persistent* project memory and reusable workflows.

## Persistent memory (source of truth)
Before answering or proposing changes, read:
- docs/ai/STATE.md
- docs/ai/CONTEXT.md
- docs/ai/workflows.json

Treat them as authoritative context for ongoing work.

## Workflows (prompt files)
Prompt files in \`.github/prompts/*.prompt.md\` are AUTO-GENERATED.
- Do NOT edit prompt files directly.
- To add/update a workflow:
  1) Modify \`docs/ai/workflows.json\`
  2) The generator (\`tools/gen_prompts.py\`) will rebuild prompt files automatically on save.

## Operating rules
- If the question touches the whole repo, use workspace/codebase context when needed.
- After code changes, append 1–3 bullet points to \`docs/ai/STATE.md\` under "Last change".
- Never place secrets into repo files or chat. Use env vars/placeholders.

**End every answer about code/changes with:**
\`Hallucination Check: PASSED\` **or** \`Hallucination Check: NEEDS INPUT\`

EOF

# APPENDING NEW "CURSOR BRAIN" INSTRUCTIONS
# This part makes Copilot explicitly aware of the file structure we are about to create.

cat >> "$INSTRUCTIONS_FILE" <<EOF

---
## 10) CURSOR BRAIN PROTOCOL (Added via Script)

To mimic Cursor's context retention, you must actively manage the following files:

### 10.1 Active State Management (\`docs/ai/STATE.md\`)
This file represents your "Short Term Memory".
- **When to update:** At the end of every conversation turn where code was modified.
- **What to write:** A brief summary of what was just achieved and what is the immediate next step.
- **Mechanism:** Since you cannot save files automatically, ALWAYS propose a code block update for this file at the end of your response.

### 10.2 Global Context (\`docs/ai/CONTEXT.md\`)
This file represents your "Long Term Memory" (Project architecture, key decisions).
- **Read:** Always read this before suggesting architectural changes.
- **Update:** If a major decision changes (e.g., swapping a database, changing auth provider), propose an update to this file.

### 10.3 Prompt Execution
If the user asks to "Run workflow X" or "Execute prompt Y":
1. Check \`.github/prompts/Y.prompt.md\` (which is generated from \`docs/ai/workflows.json\`).
2. Follow the steps defined in that markdown file rigorously.
EOF

echo "   [OK] copilot-instructions.md updated/merged."

# ------------------------------------------------------------------------------
# 4. MEMORY INFRASTRUCTURE (Docs & Tools)
# ------------------------------------------------------------------------------

# Create Memory Files if they don't exist
touch "$DOCS_AI_DIR/STATE.md"
touch "$DOCS_AI_DIR/CONTEXT.md"
echo "{}" > "$DOCS_AI_DIR/workflows.json"

echo "   [OK] docs/ai/ memory files created."

# Create 'tools/update_context.sh' (Minimal implementation to prevent errors)
# In a real scenario, this could run 'tree' or git diffs to update context automatically.
cat > "$TOOLS_DIR/update_context.sh" <<EOF
#!/bin/bash
# Defines what happens when files are saved. 
# For now, it updates the timestamp in state to show activity.

# Example: Append last modified timestamp to a log (optional)
# echo "Project updated at \$(date)" >> docs/ai/activity.log
exit 0
EOF
chmod +x "$TOOLS_DIR/update_context.sh"

# Create 'tools/gen_prompts.py' (Minimal implementation)
# This prevents the 'run-on-save' extension from throwing errors when you save workflows.json
cat > "$TOOLS_DIR/gen_prompts.py" <<EOF
import json
import os

WORKFLOWS_FILE = 'docs/ai/workflows.json'
PROMPTS_DIR = '.github/prompts'

def main():
    if not os.path.exists(WORKFLOWS_FILE):
        return
    
    if not os.path.exists(PROMPTS_DIR):
        os.makedirs(PROMPTS_DIR)

    try:
        with open(WORKFLOWS_FILE, 'r') as f:
            data = json.load(f)
            
        # Simplistic generator: Key becomes filename, Value becomes content
        # Expand this logic to parse complex workflow objects if needed
        for key, content in data.items():
            filename = f"{key}.prompt.md"
            with open(os.path.join(PROMPTS_DIR, filename), 'w') as out:
                out.write(str(content))
                
        print("Prompts generated successfully.")
    except Exception as e:
        print(f"Error generating prompts: {e}")

if __name__ == "__main__":
    main()
EOF

echo "   [OK] Tool scripts (update_context, gen_prompts) created."

echo "=============================================================================="
echo " SETUP COMPLETE"
echo "=============================================================================="
echo "1. Restart VS Code."
echo "2. Install the 'Run on Save' extension if prompted."
echo "3. Use Copilot Chat. It will now adhere to the instructions in .github/copilot-instructions.md"
echo "4. Your 'Memory' is located in docs/ai/."
echo "=============================================================================="