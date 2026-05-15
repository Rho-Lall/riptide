---
description: Capture patterns and gotchas after task completion — knowledge compounding
---

# /compound

Capture learnings from a completed task into `docs/solutions/`.

## Usage

```
/compound
/compound {TASK-ID}
```

**Argument:** Task ID (optional — if omitted, examines the most recent work)

## Steps

### 1. Review What Was Built

If task ID provided, read `.riptide/plans/{task-id}.md` and the git diff for that task's commits.

If no task ID, examine the most recent commits:
```bash
git log --oneline -10
git diff main...HEAD
```

### 2. Identify Patterns

Look for reusable approaches:
- New service/module structure
- Testing approach for a specific scenario
- API pattern or middleware chain
- Component composition pattern

For each pattern, write to `docs/solutions/pattern-{name}.md`:

```markdown
# Pattern: {Name}

## When to Use
{One-line scenario}

## Implementation
{Key approach — 2-3 lines max}

## Example
`{file path where this is implemented}`
```

**Must be < 15 lines.**

### 3. Identify Gotchas

Look for non-obvious solutions or surprising behaviors:
- Framework quirks or workarounds
- Unexpected API behavior
- Configuration pitfalls

For each gotcha, write to `docs/solutions/gotcha-{name}.md`:

```markdown
# Gotcha: {Name}

## Symptom
{What goes wrong}

## Fix
{What to do}
```

**Must be < 15 lines.**

### 4. Report

Output what was captured:

```
### Compound Complete — {TASK-ID}

**Patterns:** {list or "none"}
**Gotchas:** {list or "none"}
```

If nothing noteworthy: "No learnings to capture."

## Rules

- Keep documents under 15 lines. Brevity is the point.
- Only capture genuinely useful learnings — don't force it.
- Pattern/gotcha files are read by the Planner before every task. Keep them scannable.
- No feature docs, no ADRs. Just patterns and gotchas.
