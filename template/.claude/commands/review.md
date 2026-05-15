---
description: Multi-perspective code review — plan conformance, security, performance, isolation
---

# /review

Run a multi-perspective code review. Uses the **Tester** agent role.

## Usage

```
/review
/review {TASK-ID}
```

**Argument:** Task ID (optional — if omitted, reviews current branch diff)

## Steps

### 1. Compute Diff

```bash
git diff main...HEAD
```

If no changes, report "No changes to review" and stop.

### 2. Load Context

1. Read `.riptide/plans/{task-id}.md` (the plan to verify against)
2. Read `docs/MODULE_MAP.md` (boundary rules)
3. Read `docs/TECH_SPEC.md` (architecture expectations)

### 3. Review Perspectives

#### 3.1 — Plan Conformance
- Does the implementation match the plan's file list?
- Are function signatures as specified?
- Do tests cover every acceptance criterion?

#### 3.2 — Security
- Injection (SQL, NoSQL, command)
- Auth bypass (missing middleware, missing role checks)
- Data leakage (cross-tenant access, exposed secrets)

#### 3.3 — Performance
- N+1 queries
- Unbounded operations (no LIMIT, no pagination)
- Missing caching for expensive computations

#### 3.4 — Module Isolation
- No imports outside MODULE_MAP.md boundaries
- No writes to files owned by other waves

### 4. Update Status

Update `.riptide/status.json` — set the task's status to `"reviewing"` and agent to `"tester"`.

### 5. Write Findings

Append findings to `.riptide/plans/{task-id}.md` under a `#### Review` section:

```markdown
#### Review

**Critical** (must fix before merge)
- {finding with file:line reference}

**High** (should fix before merge)
- {finding with file:line reference}

**Medium** (fix if time allows)
- {finding with file:line reference}

**Low** (nice to have)
- {finding with file:line reference}
```

## Gate

- Any **Critical** finding → block merge
- High/Medium/Low only → review passes

## Rules

- Be specific — include file paths and line numbers.
- Don't nitpick style. Focus on correctness, security, and performance.
- If no issues found, write "#### Review\n\nNo issues found." and pass.
