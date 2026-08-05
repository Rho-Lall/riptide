# Riptide

A lean orchestration framework for one human directing 6–30 concurrent Claude Code agents through structured waves. Replaces SunForge (70KB+) with a focused tool under 15KB.

Kiro handles planning and decomposition. Claude Code terminals handle execution. A localhost dashboard provides visibility.

## Key Concepts

| Term | Definition |
|------|-----------|
| **Tide** | Collection of independent waves (parallel), delivering a milestone |
| **Wave** | Serial chain of dependent tasks in one Claude Code terminal |
| **Task** | Atomic unit of work (one issue) |
| **Agent** | Claude Code persona — Planner, Builder, Tester, or Debugger |

Waves within a tide run simultaneously with zero cross-wave dependencies. Dependencies only exist within a wave (serial task ordering). Tides are sequential milestones.

## Single-Repo vs. Multi-Repo

`bootstrap.sh` detects which mode applies and records it in `.riptide/status.json`'s `mode`
field:

- **single-repo** — the target is itself a git working tree. Waves get worktree isolation
  (`git worktree add .worktrees/wave-x`); MODULE_MAP.md owns bare path globs.
- **multi-repo** — the target is a workspace containing several independent repos (or isn't a
  git repo at all — e.g. a folder of unrelated projects). There's no single `.git` to branch
  from, so waves don't get worktree isolation; instead each wave's terminal `cd`s into
  whichever repo(s) it owns and branches normally there. MODULE_MAP.md owns
  `{repo}/{path-glob}` entries so ownership stays unambiguous across repo boundaries.

Deploy at whichever root makes sense for your project — a single repo, or the parent folder
of several. See `docs/MODULE_MAP.md` for the format each mode expects.

## Quick Start

```bash
cd ~/projects/my-app

# Deploy Riptide into this project
riptide bootstrap

# Start the dashboard
riptide dashboard

# In each Claude Code terminal (one per wave):
/sprint TASK-1 TASK-2 TASK-3
```

Each terminal runs its wave autonomously: plan → build → review → compound for each task in serial order.

## Commands

Deployed into your project's `.claude/commands/`:

| Command | Purpose |
|---------|---------|
| `/plan {TASK-ID}` | Read-only research + structured plan output |
| `/build {TASK-ID}` | Implement from plan (TDD for logic, direct for declarative) |
| `/sprint {TASK-IDs}` | Batch process tasks in serial order within a wave |
| `/review` | Multi-perspective code review |
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
.claude/
├── agents/                        # Planner, Builder, Tester, Debugger
├── commands/                      # /plan, /build, /sprint, /review, /compound
├── hooks/                         # Kill switch, module boundary, git safety
└── settings.json                  # Hook registration
.riptide/
├── status.json                    # Tide/wave/task status (dashboard reads this)
└── plans/                         # Task plans (planner writes, builder reads)
docs/
├── TECH_SPEC.md                   # Template — filled before waves start
├── MODULE_MAP.md                  # File ownership per wave
└── solutions/                     # Knowledge compounding archive
dashboard/
└── index.html                     # Single-file status dashboard (no build step)
```

Total deployed size: <15KB. Context per agent invocation: <5KB.

## Safety Mechanisms

**Kill Switch** — Automatic freeze on:
- 3 consecutive test failures on the same test
- 10+ minutes stuck without progress

**Module Boundaries** — Each wave owns specific files (defined in MODULE_MAP.md). Writing outside your boundary triggers a freeze and conflict report.

**Git Safety** — Blocks dangerous operations: force push, `reset --hard`, `clean -fd`, branch deletion of protected branches.

On any freeze: all work stops, status updates to FROZEN, agent waits for human intervention.

## vs SunForge

| Dimension | SunForge | Riptide |
|-----------|----------|---------|
| Context per agent | ~70KB | <5KB |
| Agent count | 5 (incl. Facilitator) | 4 (Kiro replaces Facilitator) |
| TDD enforcement | Every file (hook blocks) | Logic code only |
| Team coordination | 4-person webhook signals | None (one person) |
| Acceptance criteria | Gherkin (formal) | Plain English |
| File conflict prevention | REGISTRY.json (dynamic) | MODULE_MAP.md (static per tide) |
| Knowledge compounding | Full docs + ADRs | Patterns + gotchas only (<15 lines) |
| Planning overhead | Interview → PRD → Spec → Issues | Kiro produces issues directly |
| Framework docs | 70KB+ | <15KB total |

## How a Tide Runs

1. **Kiro** decomposes a milestone into tasks, groups them into waves, generates MODULE_MAP.md
2. **You** open one Claude Code terminal per wave, run `/sprint {TASK-IDs}`
3. **Each terminal** autonomously: plans, builds, reviews, compounds — task by task
4. **Dashboard** shows real-time status across all waves
5. **You** review PRs when waves complete, merge, kick off next tide

## License

MIT
