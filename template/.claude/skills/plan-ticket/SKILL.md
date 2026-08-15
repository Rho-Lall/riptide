---
name: plan-ticket
description: Produce an approved wave plan before /surf runs. Use when starting a wave, when /surf or /build reports a missing plan, or when asked to plan a ticket or a chain of tickets. Runs in native Plan Mode with the human present — never autonomously.
---

# plan-ticket

Produce the plan a wave executes from. One plan per wave, written to
`.riptide/plans/{wave-id}.md`.

This skill loads planning discipline into **your current session**. It is not an agent and does
not run unattended. The human is present, in Plan Mode, and approves the result.

## Scope: one plan, whole wave

A wave is a serial chain of dependent tickets. They are batched *because* they depend on each
other, so they are one unit of thought and get one plan.

Detail is not uniform across the chain:

- **First ticket** — full detail. It starts immediately; nothing is unknown.
- **Later tickets** — shape and acceptance criteria only. Their detail depends on what earlier
  tickets actually produce, so specifying it now is guesswork dressed as a plan.

Write `## Checkpoint` between ticket sections. `/surf` stops there, re-enters this skill, and
fills in the next ticket's detail with the previous ticket's real outcome in hand.

## Before writing

1. **Read the ticket(s).** Restate what each asks for, in your own words.
2. **Read the bar** — `docs/BAR.md`, plus any narrower bar named by a reference doc this ticket
   touches. Every plan is accountable to a bar.
3. **Read the reference design.** Either the `## Design` section of the ticket's spec, or the
   document it points at (`docs/reference/*.md`). Do not re-derive a design that already exists.
4. **Check `docs/solutions/`** for prior patterns and gotchas covering this area.
5. **Confirm ownership** — the paths you intend to touch must be inside this wave's `Owns`
   globs in `docs/CHANNELS.md`. If the work needs a file outside them, stop and say so. That
   is a decomposition error, and it is cheaper to fix now than mid-wave.

## Plan format

`/build` parses these sections. Omitting one means `/build` cannot proceed.

```markdown
# Wave {wave-id}: {name}

**Tickets**: {TICKET-1} → {TICKET-2} → {TICKET-3}
**Bar**: docs/BAR.md{, plus narrower bar if any}
**Reference**: {design doc path, or "inline below"}
**Approved**: {YYYY-MM-DD} by {human}

---

## {TICKET-1}: {title}

### Files
- `path/to/file.ts` — create | modify
    (every path must be inside this wave's channel in docs/CHANNELS.md)

### Signatures
```
functionName(arg: Type): ReturnType
```

### Test cases
- {behavior} → {expected}
    (plain English; these become the tests)

### Verification
```bash
{command that must exit 0}
```

### Bar criteria
- {which criterion from the bar this ticket is accountable to}

## Checkpoint
Re-enter `plan-ticket` before starting {TICKET-2}. Fill in its detail using what
{TICKET-1} actually produced.

---

## {TICKET-2}: {title}
### Shape
{2-4 sentences: what it does, what it depends on from TICKET-1}
### Acceptance
- {plain-English criteria}
```

## Approval

The `**Approved**:` line is the gate. `/surf` and `/build` refuse to proceed past planning
without it, and **you must never write it yourself** — it records that a human read the plan and
agreed. Present the plan, wait, and let the human approve it.

If you are running without a human present — a resumed wave, a retry after a freeze, an
automated loop — **stop**. Report that the wave has no approved plan and needs one. Do not
generate a plan and proceed. An unreviewed plan executed unattended is the failure mode this
whole design exists to prevent.

## Rules

- Plan only. Write no implementation code in this skill.
- No architecture decisions. If the design is ambiguous, ask the human — don't resolve it.
- If a ticket can't be planned without touching another wave's files, say so and stop.
- Keep it under ~150 lines. A plan longer than the code is a decomposition problem.
