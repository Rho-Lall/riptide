# Riptide

A lean orchestration framework for one human directing 6–30 concurrent Claude Code agents through structured waves. Replaces SunForge (70KB+) with a focused tool under 15KB.

You set the cadence, not an automated planning agent. `/plan-sprint` triages a ticket set into
waves; the `plan-ticket` skill plans each wave in Claude's native Plan Mode with you approving.
Claude Code terminals handle execution — one terminal per wave, surfing its tickets in order.
A localhost dashboard provides visibility.

Works two ways. **Project mode**: you decompose a known whole into a spec
(`requirements.md` → `design.md` → `tasks.md`). **Work mode**: you're handed a sprint of
mostly-unrelated tickets, each with a one-doc spec that inlines its design or points at a
shared reference doc. Both converge on a ticket set, and `/plan-sprint` takes it from there.

## Key Concepts

| Term | Definition |
|------|-----------|
| **Tide** | Collection of independent waves (parallel), delivering a milestone |
| **Wave** | Serial chain of dependent tasks in one Claude Code terminal |
| **Task** | Atomic unit of work (one issue) |
| **Agent** | Claude Code persona — Builder, Tester, or Debugger |

Waves within a tide run simultaneously with zero cross-wave dependencies. Dependencies only exist within a wave (serial task ordering). Tides are sequential milestones.

## Single-Repo vs. Multi-Repo

`bootstrap.sh` detects which mode applies and records it in `.riptide/status.json`'s `mode`
field:

- **single-repo** — the target is itself a git working tree. Waves get worktree isolation
  (`git worktree add .worktrees/wave-x`); CHANNELS.md owns bare path globs.
- **multi-repo** — the target is a workspace containing several independent repos (or isn't a
  git repo at all — e.g. a folder of unrelated projects). There's no single `.git` to branch
  from, so waves don't get worktree isolation; instead each wave's terminal `cd`s into
  whichever repo(s) it owns and branches normally there. CHANNELS.md owns
  `{repo}/{path-glob}` entries so ownership stays unambiguous across repo boundaries.

Deploy at whichever root makes sense for your project — a single repo, or the parent folder
of several. See `docs/CHANNELS.md` for the format each mode expects.

## Quick Start

```bash
cd ~/projects/my-app

# Deploy Riptide into this project
riptide bootstrap

# Start the dashboard
riptide dashboard

# Triage the sprint (orchestrator terminal, once):
/plan-sprint ABC-123 ABC-140 ABC-201 ABC-119

# In each Claude Code terminal (one per wave):
/surf TICKET-1 TICKET-2 TICKET-3
```

Each terminal surfs its wave: plan (phase 0, you approve) → build + compound ticket by ticket
→ `/gauntlet` at the end. A wave whose plan at `.riptide/plans/{wave-id}.md` is missing or
unapproved stops and tells you — and stops without generating one if no human is present.

The gauntlet is the quality gate: blind critics, fresh context each round, scoring the finished
wave against `docs/BAR.md` until the gap score hits your threshold.

## Commands

Deployed into your project's `.claude/commands/`:

| Command | Purpose |
|---------|---------|
| `/plan-sprint {TICKET-IDs}` | Triage a ticket set into waves — what's parallel, what's sequential |
| `/build {TICKET-ID}` | Implement from plan (TDD for logic, direct for declarative) |
| `/surf {TICKET-IDs}` | Surf one wave — process its tickets in serial order |
| `/gauntlet` | Blind critics score the wave against the bar, iterate to threshold |
| `/compound` | Capture patterns/gotchas after task completion |

## Scripts

Run via the `riptide` CLI from within your project directory:

| Command | Purpose |
|---------|---------|
| `riptide bootstrap` | Deploy Riptide into the current directory |
| `riptide teardown` | Remove Riptide from the current directory |
| `riptide dashboard` | Start localhost status dashboard |

## What Gets Deployed

Running `bootstrap.sh` copies the following into your project:

```
CLAUDE.md                          # Shared agent rules (<1KB)
RIPTIDE.md                         # Human usage guide
.claude/
├── agents/                        # Builder, Tester, Debugger
├── commands/                      # /plan-sprint, /build, /surf, /gauntlet, /compound
├── skills/                        # plan-ticket — wave planning in Plan Mode
├── hooks/                         # Kill switch, channels, git safety
└── settings.json                  # Hook registration
.riptide/
├── status.json                    # Tide/wave/task status (dashboard reads this)
└── plans/                         # Wave plans (written via native Plan Mode, builder reads)
docs/
├── TECH_SPEC.md                   # Template — filled before waves start
├── BAR.md                         # References, metrics, scoring, threshold
├── CHANNELS.md                    # File ownership per wave
└── solutions/                     # Knowledge compounding archive
dashboard/
└── index.html                     # Single-file status dashboard (no build step)
```

Total deployed size: <15KB. Context per agent invocation: <5KB.

## Project Docs

Riptide's own documentation lives in `docs/` at this repo root (not deployed to target
projects):

- `docs/specs/{feature}/` — specs. Project mode uses `requirements.md` → `design.md` →
  `tasks.md`; work-mode tickets use a single doc with design inline or referenced.
  `docs/specs/riptide/` is Riptide's own spec and the worked example of the long form.
- `docs/KNOWN_ISSUES.md` — open defects and unverified assumptions. **Read this before
  relying on channel enforcement.**

## Safety Mechanisms

**Kill Switch** — Automatic freeze on:
- 3 consecutive test failures on the same test
- 10+ minutes stuck without progress

**Channels** — Each wave owns specific files (defined in CHANNELS.md). Writing outside your channel triggers a freeze and a crossed-channels report.

**Git Safety** — Blocks dangerous operations: force push, `reset --hard`, `clean -fd`, branch deletion of protected branches.

On any freeze: all work stops, status updates to FROZEN, agent waits for human intervention.

## vs SunForge

| Dimension | SunForge | Riptide |
|-----------|----------|---------|
| Context per agent | ~70KB | <5KB |
| Agent count | 5 (incl. Facilitator) | 3 (Builder, Tester, Debugger — no Planner or Facilitator) |
| TDD enforcement | Every file (hook blocks) | Logic code only |
| Team coordination | 4-person webhook signals | None (one person) |
| Acceptance criteria | Gherkin (formal) | Plain English |
| File conflict prevention | REGISTRY.json (dynamic) | CHANNELS.md (static per tide) |
| Knowledge compounding | Full docs + ADRs | Patterns + gotchas only (<15 lines) |
| Planning overhead | Interview → PRD → Spec → Issues | /plan-sprint sets cadence; per-wave plans via native Plan Mode |
| Framework docs | 70KB+ | <15KB total |

## How a Tide Runs

1. **You** set the bar in `docs/BAR.md`, then run `/plan-sprint {TICKET-IDs}` — it finds what's parallel, assigns waves, writes `docs/CHANNELS.md` and `.riptide/status.json`
2. **You** open one Claude Code terminal per wave, run `/surf {TICKET-IDs}`
3. **Each wave** plans itself first (`plan-ticket` skill, native Plan Mode) — **you approve**
4. **Each terminal** then runs autonomously: builds and compounds ticket by ticket, then runs `/gauntlet` against the bar
5. **Dashboard** shows real-time status across all waves
6. **You** review PRs when waves complete, merge, kick off next tide

## License

MIT
