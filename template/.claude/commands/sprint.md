---
description: Batch process tasks in serial order — build/review/compound for each
---

# /sprint

Process multiple tasks in serial order. Runs the full pipeline for each task within a wave.

Planning is NOT part of this pipeline — each task must already have an approved plan at
`.riptide/plans/{task-id}.md` before `/sprint` runs, produced upfront via Claude's native Plan
Mode (see the `plan-ticket` skill), not by an autonomous planning agent.

## Usage

```
/sprint {TASK-ID-1} {TASK-ID-2} {TASK-ID-3}
```

**Arguments:** One or more task IDs (space-separated, in execution order)

## Execution

Tasks are processed in the order given. Each task depends on the previous within a wave — no dependency resolution needed.

### For Each Task (in order):

1. `/build {TASK-ID}` — Implement from plan (stops if no plan exists — see above)
2. `/review {TASK-ID}` — Self-review the implementation
3. `/compound {TASK-ID}` — Capture learnings

Update `.riptide/status.json` at each transition.

### On Freeze

If any task triggers a FREEZE (kill switch):
1. Stop the sprint immediately.
2. Do NOT continue to the next task.
3. Report which task froze and why.

### On Completion

After all tasks complete, output a summary:

```
### Sprint Summary

**Completed:**
- {TASK-1}: {title} — complete
- {TASK-2}: {title} — complete

**Frozen:**
- {TASK-3}: {title} — {reason}

**Progress:** {completed}/{total} tasks
**Solutions captured:** {list of new pattern/gotcha files}
```

## Rules

- Process tasks strictly in the order given.
- Each task goes through all 4 stages before the next task starts.
- If a task freezes, the sprint stops — don't skip ahead.
- Update `.riptide/status.json` throughout execution.
