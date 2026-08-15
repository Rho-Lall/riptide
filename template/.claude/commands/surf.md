---
description: Surf one wave — plan, then build/verify/compound each ticket, then run the gauntlet
---

# /surf

Surf one wave: process its tickets in serial order, running the full pipeline for each.

One terminal surfs one wave. Waves run in parallel across terminals; tickets within a wave run
strictly in sequence.

## Phase 0 — Plan

Before any ticket runs, this wave needs an approved plan at `.riptide/plans/{wave-id}.md`.
One plan covers the whole wave.

- **Plan exists and carries an `**Approved**:` line** → proceed to execution.
- **Plan is missing or unapproved, human present** → invoke the `plan-ticket` skill. Plan the
  wave in native Plan Mode, let the human approve it, then proceed.
- **Plan is missing or unapproved, no human present** → **STOP**. Report that the wave is
  unplanned and wait. Do not generate a plan and continue.

That last case is not a formality. A resumed wave, a retry after a freeze, or an automated
loop can all reach this point with nobody watching, and a self-approved plan executed
unattended is precisely the failure this design exists to prevent. Fail closed.

## Usage

```
/surf {TICKET-ID-1} {TICKET-ID-2} {TICKET-ID-3}
```

**Arguments:** One or more task IDs (space-separated, in execution order)

## Execution

Tasks are processed in the order given. Each task depends on the previous within a wave — no dependency resolution needed.

### For Each Task (in order):

1. `/build {TICKET-ID}` — Implement from the wave plan's section for this ticket
2. `/compound {TICKET-ID}` — Capture learnings

Per-ticket quality gating is `/build`'s verification step: the plan's verification commands
must exit 0 before the next ticket starts. Standards are judged once, at the end of the wave.

Update `.riptide/status.json` at each transition.

### On Freeze

If any task triggers a FREEZE (kill switch):
1. Stop the wave immediately.
2. Do NOT continue to the next task.
3. Report which task froze and why.

### On Completion

After all tasks complete, output a summary:

```
### Wave Summary

**Completed:**
- {TASK-1}: {title} — complete
- {TASK-2}: {title} — complete

**Frozen:**
- {TASK-3}: {title} — {reason}

**Progress:** {completed}/{total} tasks
**Solutions captured:** {list of new pattern/gotcha files}
```

## Phase 2 — Gauntlet

Once every ticket is complete, run `/gauntlet`. Blind critics score the wave's finished work
against `docs/BAR.md` and iterate until the gap score reaches the threshold.

This runs once per wave, not per ticket. A half-built chain fails metrics it was never going
to meet mid-wave, and per-ticket critique costs several fresh-context spawns per round.

If the gauntlet freezes — round cap, or a gap that stops falling — the wave stops there and
waits for a human. Don't merge past a frozen gauntlet.

## Rules

- Process tickets strictly in the order given.
- At a `## Checkpoint` in the plan, stop and re-enter `plan-ticket` to detail the next ticket
  using what the previous one actually produced.
- Never write the `**Approved**:` line yourself.
- Each task goes through all 4 stages before the next task starts.
- If a ticket freezes, the wave stops — don't skip ahead.
- Update `.riptide/status.json` throughout execution.
