---
description: Implement a planned task — TDD for logic, direct write for declarative
---

# /build

Implement a task from its plan. Uses the **Builder** agent role.

## Usage

```
/build {TASK-ID}
```

## Steps

### 1. Read Plan

Read the plan from `.riptide/plans/{task-id}.md`. Parse:
- Files to create/modify
- Service function signatures
- Test cases
- Verification commands

If no plan exists, stop. Planning happens upfront via Claude's native Plan Mode (see the
`plan-ticket` skill), not by an autonomous agent — there's no `/plan` command to fall back to.
Tell the human this task hasn't been planned yet.

### 2. Update Status

Update `.riptide/status.json` — set the task's status to `"building"` and agent to `"builder"`.

### 3. Implement

**For logic code** (services, calculations, business rules):
1. **RED** — Write the test. Run it. Confirm it fails.
2. **GREEN** — Write minimal code to pass.
3. **REFACTOR** — Clean up without changing behavior.
4. **COMMIT** — Atomic commit.

**For declarative code** (config, manifests, migrations, XML):
1. Write the file following existing patterns.
2. Verify syntax is valid.
3. Commit.

### 4. Commit

Format: `{type}: {description} [{TASK-ID}]`

Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`

One concern per commit. No multi-purpose commits.

### 5. Verify

Run the verification commands from the plan. All must pass.

### 6. Update Status

Update `.riptide/status.json`:
- On success: status → `"complete"`
- On freeze: status → `"frozen"`, include reason

## Kill Switch

Monitor these conditions throughout:

- **3 consecutive failures on the same test** → FREEZE
- **10 minutes stuck without progress** → FREEZE

On freeze:
1. Stop ALL work immediately.
2. Update `.riptide/status.json` with status `"frozen"` and reason.
3. Write freeze details to `.riptide/plans/{task-id}.md`.
4. Do NOT continue. Wait for human intervention.

## Rules

- Follow the plan. Don't make architecture decisions.
- Stay within your wave's module boundary (MODULE_MAP.md).
- Check `docs/solutions/` before implementing — reuse existing patterns.
- Never force push. Never reset --hard.
