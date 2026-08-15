---
description: Triage a set of tickets into waves — find what's parallel, what's sequential, set the order
---

# /plan-sprint

Take a set of tickets and work out their shape: what can run in parallel, what must run in
sequence. Output is a wave assignment, not an implementation plan.

Run this **once per sprint, in the orchestrator terminal**, before any wave launches.

## Usage

```
/plan-sprint {TICKET-ID-1} {TICKET-ID-2} {TICKET-ID-3} ...
```

## What this is not

This does **not** plan how to implement anything. It sets cadence — the order you work in and
what can run at the same time. Per-wave implementation planning happens later, in the wave's
own terminal, via the `plan-ticket` skill.

Keep it high level. If you find yourself writing function signatures, you've gone too deep.

## Steps

### 1. Read the tickets

For each ticket, establish: what it changes, and which files or components it will most likely
touch. You need enough to judge overlap — not enough to implement.

Where a ticket references a design doc (`docs/reference/*.md`) or has a `## Design` section,
skim it for the components involved.

### 2. Find the dependency structure

Two tickets are **sequential** if either is true:

- **Logical** — one needs the other's output to exist. B extends an API that A introduces.
- **Territorial** — both write the same files. Even unrelated tickets collide if they edit the
  same module, and a collision mid-sprint costs more than serializing here.

Otherwise they are **parallel**. Most tickets in a work sprint are genuinely orthogonal —
don't invent dependencies to tidy the graph. Orthogonal is the good case.

State the reasoning briefly for each dependency you assert. A dependency you can't justify in
one sentence probably isn't one.

### 3. Assign waves

- Each chain of sequential tickets becomes one wave, in dependency order.
- Each independent ticket becomes its own single-ticket wave.
- Waves are lettered: `wave-a`, `wave-b`, `wave-c`.
- Waves within a tide must have **zero** cross-wave dependencies. If two waves depend on each
  other, they're one wave, or they belong in different tides.
- Size each wave to roughly one working session (~90 minutes of agent work). Split what's
  larger across tides.

Cap the wave count at the number of terminals you'll actually open. Six waves and three
terminals means two tides.

### 4. Write the channels

Update `docs/CHANNELS.md` with each wave's file ownership. Use the format matching
`.riptide/status.json`'s `mode` field — bare globs for single-repo, `{repo}/{path-glob}` for
multi-repo.

**Channels must not overlap.** Overlapping globs across two waves is the exact failure this
step exists to prevent — if you can't separate them, the tickets belong in the same wave.

### 5. Write the sprint state

Write `.riptide/status.json`:

```json
{
  "tide": "{sprint name}",
  "waves": [
    {
      "id": "wave-a",
      "name": "{short label}",
      "tasks": [
        {"id": "ABC-123", "title": "...", "status": "pending"},
        {"id": "ABC-140", "title": "...", "status": "pending"}
      ]
    }
  ],
  "frozen": []
}
```

All tasks start `pending`. The dashboard reads this file.

### 6. Report

Output the plan for human review:

```
### Sprint: {name}

**Wave A** — {label}
  ABC-123 → ABC-140          (sequential: ABC-140 extends ABC-123's endpoint)
  Channel: `src/billing/**`

**Wave B** — {label}
  ABC-201                    (independent)
  Channel: `src/auth/**`

**Tides:** 1 (all waves fit available terminals)
**Unresolved:** {tickets you couldn't place, and why}
```

Flag anything you couldn't resolve rather than guessing. A ticket whose scope is unclear is a
question for the human, not a coin flip.

## Next

Each wave still needs its own plan before it runs. In the wave's terminal, use the
`plan-ticket` skill, then `/surf {TICKET-IDs}`.

## Rules

- Cadence only — no implementation detail.
- Don't invent dependencies. Orthogonal tickets are the good case.
- Channels must not overlap between waves.
- Report tickets you couldn't place; never guess at scope.
