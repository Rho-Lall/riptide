---
description: Research a task and produce a structured implementation plan
---

# /plan

Research the codebase and produce a structured plan for a task. Uses the **Planner** agent role (read-only — no code writing).

## Usage

```
/plan {TASK-ID}
```

## Steps

### 1. Load Context

Read these in order:
1. `CLAUDE.md` (shared rules)
2. `docs/TECH_SPEC.md` (stack, data model, API surface)
3. `docs/MODULE_MAP.md` (your wave's file ownership)
4. `docs/solutions/*.md` (prior patterns and gotchas)

### 2. Research Codebase

- Examine existing patterns in the relevant module
- Identify shared utilities to reuse
- Check how similar features are structured
- Note any constraints from MODULE_MAP.md boundaries

### 3. Write Plan

Write the plan to `.riptide/plans/{task-id}.md` using this format:

```markdown
### Plan: {TASK-ID}

**Module:** {package/module name}
**Complexity:** S / M / L

#### Files to Create/Modify
- `path/to/file.ext` — {what and why}
- `path/to/test_file.ext` — {what's tested}

#### Service Functions
- `functionName(arg: Type) → ReturnType` — {key logic}

#### Tests
- {plain English: what this test verifies}

#### Verify
```bash
{exact commands to verify correctness}
```
```

### 4. Update Status

Update `.riptide/status.json` — set the task's status to `"planning"` and agent to `"planner"`.

## Rules

- You are READ-ONLY. Never create or modify source code files.
- Every acceptance criterion must map to at least one test case.
- Every file reference must include its full path.
- If something is unclear, note it in the plan as an open question.
- Stay within your wave's module boundary (see MODULE_MAP.md).
