# Riptide — Usage Guide

Riptide is a lean orchestration framework for directing multiple concurrent Claude Code agents through structured waves. One human, many terminals, zero chaos.

## Key Concepts

| Term | Definition |
|------|-----------|
| **Tide** | A milestone — collection of waves that run in parallel |
| **Wave** | A serial chain of dependent tasks in one Claude Code terminal |
| **Task** | Atomic unit of work (one issue) |
| **Agent** | Claude Code persona — Builder, Tester, or Debugger |

Waves within a tide run simultaneously with zero cross-wave dependencies. Dependencies only exist within a wave (serial task ordering). Tides are sequential milestones.

## Before You Start

1. **Fill in `docs/TECH_SPEC.md`** — stack, data model, API surface, constraints. Agents load it as context.
2. **Set the bar** — fill in `docs/BAR.md`: the references you're holding work against, numbered metrics with measured values and fail conditions, and the gap threshold that means done.
3. **Triage the sprint** — run `/plan-sprint {TICKET-IDs}` in the orchestrator terminal. It finds what's parallel and what's sequential, assigns waves, and writes `docs/CHANNELS.md` + `.riptide/status.json`.
4. **Plan each wave** — in the wave's terminal, use the `plan-ticket` skill in native Plan Mode. One plan per wave, approved by you, at `.riptide/plans/{wave-id}.md`.

You set cadence and approve plans. There's no automated planning agent.

### Project mode vs. work mode

Both work. They differ only in what the spec looks like, then converge:

- **Project mode** — you decompose a known whole. Spec is `requirements.md` → `design.md` → `tasks.md`.
- **Work mode** — you're handed a sprint of mostly-unrelated tickets. Each ticket's spec is one doc, with design inline or pointing at a shared `docs/reference/*.md`.

Either way you end up with a ticket set, and `/plan-sprint` takes it from there.

## Workflow

```
1. You write TECH_SPEC.md + BAR.md
2. /plan-sprint TICKET-1 ... TICKET-N  → waves, channels, status.json
3. Open one Claude Code terminal per wave
4. In each terminal: /surf TICKET-1 TICKET-2 TICKET-3
     ├─ phase 0: plan the wave (plan-ticket skill), you approve
     ├─ phase 1: build + compound, ticket by ticket
     └─ phase 2: /gauntlet — blind critics vs. the bar, iterate to threshold
5. Monitor progress via the dashboard
6. Review PRs when waves complete, merge, start next tide
```

## Commands (available in Claude Code terminals)

| Command | Purpose |
|---------|---------|
| `/plan-sprint {TICKET-IDs}` | Triage a ticket set into waves — what's parallel, what's sequential |
| `/build {TICKET-ID}` | Implement from plan (TDD for logic, direct for declarative) |
| `/surf {TICKET-IDs}` | Surf one wave — plan, build its tickets in order, then gauntlet |
| `/gauntlet` | Blind critics score the wave against the bar, iterate to threshold |
| `/compound` | Capture patterns/gotchas after task completion |

Wave planning is not a slash command — it's the `plan-ticket` skill, invoked in native Plan
Mode with you present. `/plan-sprint` sets cadence only; it plans no implementation.

## Agent Context Order

When an agent starts work, it reads context in this order:

```
CLAUDE.md → docs/TECH_SPEC.md → docs/BAR.md → docs/CHANNELS.md → docs/solutions/ → .riptide/plans/{wave-id}.md
```

## Dashboard

Start the status dashboard from the project root:

```bash
riptide dashboard
```

Or directly:

```bash
open dashboard/index.html
```

The dashboard reads `.riptide/status.json` for real-time wave/task status.

## File Structure

```
CLAUDE.md                    # Agent rules (agents read this first)
RIPTIDE.md                   # This file — human usage guide
.claude/
├── agents/                  # Agent personas (Builder, Tester, Debugger)
├── commands/                # Slash commands (/plan-sprint, /build, /surf, /gauntlet, /compound)
├── skills/                  # plan-ticket — wave planning in native Plan Mode
├── hooks/                   # Safety hooks (kill switch, channels, git)
└── settings.json            # Hook registration
.riptide/
├── status.json              # Live tide/wave/task status + mode
└── plans/                   # Wave plans (approved in Plan Mode, builder reads)
dashboard/
└── index.html               # Single-file status dashboard
docs/
├── TECH_SPEC.md             # Architecture, data model, API surface
├── BAR.md                   # References, metrics, scoring, threshold
├── CHANNELS.md              # File ownership per wave — stay in your channel
└── solutions/               # Knowledge compounding archive
```

## Safety Mechanisms

- **Kill Switch** — Auto-freeze on 3 consecutive test failures or 10+ minutes stuck
- **Gauntlet** — Freezes if the gap score stops falling, rises, or hits the round cap
- **Channels** — Writing outside your wave's channel triggers a freeze
- **Git Safety** — Blocks force push, reset --hard, clean -fd, protected branch deletion

On any freeze: all work stops, status updates to FROZEN, agent waits for human intervention.

## Status Flow

```
start → planning → building → reviewing → complete
                                         ↘ frozen (on safety trigger)
```

Agents update `.riptide/status.json` on every transition.

## Tips

- Keep waves independent — no cross-wave file dependencies
- One terminal = one wave = one serial task chain
- Check `docs/solutions/` before implementing (prior patterns live there)
- After completing a task, `/compound` captures what you learned
- The gauntlet runs once per wave, not per ticket — it scores finished work
- Never lower a threshold to make a round pass; amend `docs/BAR.md` in the open instead
- The dashboard auto-refreshes — leave it open in a browser tab
