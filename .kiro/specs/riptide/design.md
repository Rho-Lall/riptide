# Design: Riptide

## What It Is

A lean orchestration framework for one human directing 6-30 concurrent Claude Code agents through structured waves. Kiro handles planning and decomposition. Claude Code terminals handle execution. A lightweight localhost dashboard provides visibility.

**Replaces**: SunForge (70KB+ of context, hackathon team coordination overhead, Facilitator agent, Gherkin, training wheels for non-developers)

**Keeps**: Worktree isolation, Plan/Build/Review/Compound cycle, Kill switch, Module boundaries, Knowledge compounding

**Drops**: Linear dependency (replaced by local status file + dashboard)

---

## Core Concepts

### Vocabulary

| Term | Definition |
|------|-----------|
| **Tide** | A collection of independent waves that run in parallel, delivering a milestone. Tides are sequential — Tide 2 starts after Tide 1 completes. |
| **Wave** | A serial chain of dependent tasks processed by one Claude Code terminal. Tasks within a wave run in sequence because each depends on the previous. |
| **Task** | A single Linear issue. The atomic unit of work. Assigned to one wave. |
| **Agent** | A Claude Code persona (Planner, Builder, Tester, Debugger). Each task moves through agents sequentially within its wave. |

**Key constraints**:
- Dependencies exist WITHIN a wave (serial execution)
- Waves within a tide are fully independent (parallel execution, no cross-wave dependencies)
- Tides are milestones — sequential checkpoints even if more parallelism is theoretically possible

### Execution Model

```
You (Kiro) ─── decomposes into ──→ Tide 1 (milestone)
                                      │
                                      ├── Wave A (terminal 1) ─── serial ───→
                                      │     Task 1 → Task 2 → Task 3
                                      │
                                      ├── Wave B (terminal 2) ─── serial ───→
                                      │     Task 4 → Task 5
                                      │
                                      └── Wave C (terminal 3) ─── serial ───→
                                            Task 6 → Task 7

                                   All waves run simultaneously.
                                   No dependencies between waves.
                                   Dependencies only within a wave.
```

**Key constraint**: No wave depends on another wave within the same tide. If Task X depends on Task Y, they must be in the same wave (serial) or in different tides (sequential milestones).

### Role Split: Kiro vs Claude Code

| Responsibility | Who |
|---------------|-----|
| Discovery, requirements, design | Kiro |
| Issue decomposition into tides/waves | Kiro |
| File ownership assignment per wave | Kiro |
| Task file creation | Kiro |
| Plan → Build → Test → Compound execution | Claude Code (per terminal) |
| Kill switch response | Human (you) |
| PR merge decisions | Human (you) |
| Knowledge compounding review | Human (you) |
| Status visibility | Localhost dashboard |

---

## Architecture

### Riptide Repo Structure

```
riptide/
├── README.md                    # What it is, how to use it
├── scripts/
│   ├── bootstrap.sh             # Deploy Riptide into a target project
│   ├── teardown.sh              # Remove Riptide from a target project
│   └── dashboard.sh             # Start the localhost status dashboard
└── template/                    # What gets deployed into target projects
    ├── CLAUDE.md                # <1KB — shared rules (loaded by every agent)
    ├── .claude/
    │   ├── agents/
    │   │   ├── planner.md       # ~1.5KB — read-only research + plan output
    │   │   ├── builder.md       # ~2KB — implement from plan
    │   │   ├── tester.md        # ~1KB — multi-perspective review
    │   │   └── debugger.md      # ~1KB — root cause analysis
    │   ├── commands/
    │   │   ├── plan.md          # /plan {TASK-ID}
    │   │   ├── build.md         # /build {TASK-ID}
    │   │   ├── sprint.md        # /sprint {TASK-IDs...}
    │   │   ├── review.md        # /review
    │   │   └── compound.md      # /compound
    │   ├── hooks/
    │   │   ├── kill-switch.sh   # 3 failures or 10min stuck = freeze
    │   │   ├── module-boundary.sh  # Warn on cross-module writes
    │   │   └── block-dangerous-git.sh
    │   └── settings.json        # Hook registration
    ├── .riptide/                 # Runtime state (gitignored in target project)
    │   ├── status.json          # Tide/wave/task status (dashboard reads this)
    │   └── plans/               # Task plan files (planner writes, builder reads)
    ├── docs/
    │   ├── TECH_SPEC.md         # Template — filled by Kiro before waves start
    │   ├── MODULE_MAP.md        # Template — file ownership per wave
    │   └── solutions/           # Knowledge compounding archive (starts empty)
    └── dashboard/
        └── index.html           # Single-file dashboard (auto-refresh, no build step)
```

**Total deployed size target: <20KB** (including dashboard HTML)
**Context per agent invocation: <5KB** (excluding source files)

### Deploy / Remove Model

**`scripts/bootstrap.sh {target-project-path}`**:
- Copies `template/` contents into the target project
- Creates `.riptide/plans/` and `docs/solutions/` directories
- Initializes `.riptide/status.json` with empty structure
- Adds `.riptide/` to the target project's `.gitignore`
- Idempotent — safe to run again if files already exist

**`scripts/teardown.sh {target-project-path}`**:
- Removes `.claude/` directory
- Removes `CLAUDE.md`
- Removes `.riptide/` directory
- Removes `docs/TECH_SPEC.md`, `docs/MODULE_MAP.md`, `docs/solutions/`
- Removes `dashboard/`
- Leaves project source code untouched

**`scripts/dashboard.sh {target-project-path}`**:
- Starts a lightweight HTTP server serving `dashboard/index.html`
- Watches `.riptide/status.json` for changes
- Opens browser to `localhost:3000`

### What's NOT Deployed

- No AGENTS.md (19KB) — rules live in CLAUDE.md (<1KB) + individual agent files
- No HACKATHON_FRAMEWORK.md (51KB) — build docs, not runtime
- No Facilitator agent — Kiro does this
- No TEAM_CONFIG.md — one person, no team coordination
- No REGISTRY.json — module boundaries are static per tide, defined in MODULE_MAP.md
- No webhook signals — dashboard provides visibility
- No Linear dependency — status lives in local JSON, plans in local markdown
- No Gherkin — acceptance criteria are plain English
- No AC Traceability Matrix — trust the tests, skip the paperwork
- No `/kickoff`, `/discover`, `/draft-prd`, `/draft-spec`, `/draft-issues` — Kiro handles all planning
- No `/status` — dashboard provides this
- No `/mock` — no guaranteed API contract mechanism yet

---

## Agent Roles (Simplified)

### Planner

**Purpose**: Read the codebase + Linear issue, produce a structured plan. Never writes code.

**Context loaded**: CLAUDE.md + TECH_SPEC.md + MODULE_MAP.md + docs/solutions/ + relevant source files

**Output**: Plan posted to Linear issue with:
- Files to create/modify (explicit paths)
- Service function signatures
- Test cases (plain English, one per acceptance criterion)
- Verification commands

**Stripped from SunForge**: No gherkin parsing, no human review checklist (you review in Linear), no "refuse to start" ceremony (just warn and proceed).

---

### Builder

**Purpose**: Implement from plan. TDD when it makes sense, skip for declarative code (XML views, config).

**Context loaded**: CLAUDE.md + the plan from Linear + MODULE_MAP.md (to verify boundaries) + relevant existing source files

**Rules**:
- Follow the plan. Don't make architecture decisions.
- For logic code (services, calculations): write test first, then implement.
- For declarative code (Odoo XML views, manifests, config): just write it.
- Atomic commits, one concern per commit.
- Kill switch: 3 consecutive test failures on same test = FREEZE.

**Stripped from SunForge**: No mandatory TDD on every file, no pre-flight ceremony (just check branch is clean), no worktree creation (already in one), no REGISTRY.json management.

---

### Tester

**Purpose**: Review the code. Run tests. Flag issues.

**Context loaded**: Git diff + CLAUDE.md + TECH_SPEC.md

**Checks**:
- Does it match the plan?
- Security: injection, auth bypass, data leakage
- Performance: N+1 queries, unbounded operations
- Module isolation: no cross-boundary imports that shouldn't exist

**Output**: Findings posted to Linear (Critical/High/Medium/Low). Critical = block merge.

**Stripped from SunForge**: No vision gate, no AC traceability matrix, no gherkin mapping.

---

### Debugger

**Purpose**: When something breaks, find and fix the root cause.

**Protocol**: Reproduce → Hypothesize → Test → Fix → Prevent (regression test + gotcha doc if non-obvious)

**Stripped from SunForge**: No 6-step ceremony. Just fix it and document if it was surprising.

---

## The Plan Format (Simplified)

What the Planner outputs to Linear:

```markdown
### Plan: {ISSUE-ID}

**Module:** {package/module name}
**Complexity:** S / M / L

#### Changes
- `path/to/file.py` — {what and why}
- `path/to/test_file.py` — {what's tested}

#### Service Functions
- `function_name(args) → ReturnType` — {key logic}

#### Tests
- {plain English description of what each test verifies}

#### Verify
```bash
{exact commands to verify it works}
```
```

That's it. No data model tables, no API blocks, no human review checklist. The plan is a concise instruction set for the Builder.

---

## Module Map (Wave Isolation)

Generated by Kiro before a tide starts. Tells each wave exactly what it owns. No "depends on" between waves — that concept doesn't exist within a tide.

```markdown
# MODULE_MAP.md

## Tide 1: Pest Control Bookkeeping

### Wave A: platform_core
**Worktree**: `.worktrees/wave-a-platform-core`
**Branch**: `feature/wave-a-platform-core`
**Owns**:
- `addons/platform_core/**`
**Tasks** (serial): ISSUE-1 → ISSUE-2 → ISSUE-3

### Wave B: pc_bookkeeping
**Worktree**: `.worktrees/wave-b-pc-bookkeeping`
**Branch**: `feature/wave-b-pc-bookkeeping`
**Owns**:
- `addons/pc_bookkeeping/**`
**Tasks** (serial): ISSUE-4 → ISSUE-5
```

**Rule**: If a wave's task needs to touch a file outside its ownership, it FREEZES and reports the conflict. You resolve it by either reassigning the file or restructuring the tides.

---

## Knowledge Compounding (Lean Version)

After each wave merges:

1. If a new pattern was established → `docs/solutions/pattern-{name}.md` (< 15 lines)
2. If something surprising happened → `docs/solutions/gotcha-{name}.md` (< 15 lines)

That's it. No feature docs, no ADRs, no broadcast signals. Just patterns and gotchas that the next Planner reads.

---

## Kill Switch (Unchanged from SunForge)

- 3 consecutive test failures on same test → FREEZE
- 10+ minutes stuck without progress → FREEZE

On freeze:
1. Stop all work
2. Write FROZEN status to `.riptide/status.json`
3. Write freeze details to the task's plan file
4. Wait for human

This is the single most important safety mechanism. It prevents token burn.

---

## Status Dashboard

### The Problem It Solves

You have 6 terminals running simultaneously. You need to see at a glance: what's in progress, what's done, what's frozen, and what learnings have been captured. Without burning tokens on API calls.

### How It Works

```
Agent state change → writes to .riptide/status.json (one line)
Dashboard (localhost) → reads status.json → renders tide/wave/task grid
```

### Status File (`.riptide/status.json`)

```json
{
  "tide": "Tide 1: Platform Core + Bookkeeping",
  "waves": [
    {
      "id": "wave-a",
      "name": "platform_core",
      "branch": "feature/wave-a-platform-core",
      "tasks": [
        {"id": "001", "title": "QB OAuth model", "status": "complete", "agent": "builder"},
        {"id": "002", "title": "QB API client", "status": "in_progress", "agent": "builder"},
        {"id": "003", "title": "Token refresh", "status": "pending", "agent": null}
      ]
    },
    {
      "id": "wave-b",
      "name": "pc_bookkeeping",
      "branch": "feature/wave-b-pc-bookkeeping",
      "tasks": [
        {"id": "004", "title": "Categorization engine", "status": "in_progress", "agent": "planner"},
        {"id": "005", "title": "Transaction sync", "status": "pending", "agent": null}
      ]
    }
  ],
  "solutions": ["pattern-qb-auth.md", "gotcha-odoo-cron.md"],
  "frozen": []
}
```

### Dashboard UI

A single HTML file with auto-refresh (file watcher or polling). No framework, no build step. Shows:

- **Tide header** with overall progress (X/Y tasks complete)
- **Wave columns** — one per wave, showing task status (pending → planning → building → reviewing → complete → frozen)
- **Frozen alerts** — red banner if any wave is frozen, with the reason
- **Solutions feed** — list of patterns/gotchas captured this tide

Runs on `localhost:3000` (or any port). Start with `python -m http.server` or a tiny Node script with file watching.

### Agent Cost

Writing a status update is one JSON file write — negligible tokens. No API calls, no auth, no response parsing. The agent just updates its task's status field when it transitions between stages.

### Token Budget

The status write adds maybe 50 tokens per state change (5-6 changes per task). For a tide with 12 tasks, that's ~600 tokens total on status updates. Compare to Linear API calls which would be 500-1000 tokens PER call (auth + request + response parsing + error handling).

---

## CLAUDE.md (Target: <3KB)

The entire agent instruction set that every terminal loads:

```markdown
# CLAUDE.md

## Rules
1. Read your task's plan file before starting any work.
2. Stay within your module boundary (see MODULE_MAP.md).
3. For logic code: test first, then implement. For declarative code: just write it.
4. Atomic commits. One concern per commit.
5. If 3 consecutive test failures on same test: FREEZE. Update status. Stop.
6. If stuck 10+ minutes: FREEZE. Update status. Stop.
7. Don't make architecture decisions. Follow the plan.
8. Before implementing, check docs/solutions/ for relevant patterns.
9. After completing a task, capture any new pattern or gotcha in docs/solutions/.
10. Update .riptide/status.json when transitioning between stages.

## Context Loading Order
1. This file (CLAUDE.md)
2. docs/TECH_SPEC.md (data model, API surface, stack decisions)
3. docs/MODULE_MAP.md (your wave's file ownership + task list)
4. docs/solutions/*.md (prior learnings)
5. Your task's plan file (in .riptide/plans/)

## Agent Roles
- /plan — read-only research, output structured plan to .riptide/plans/
- /build — implement from plan, TDD for logic, direct write for declarative
- /review — multi-perspective code review, write findings to plan file
- /compound — capture patterns/gotchas after task completion

## Commit Format
{type}: {description} [{TASK-ID}]

Types: feat, fix, test, refactor, docs, chore

## Status Updates
Write to .riptide/status.json when:
- Starting a task (pending → planning/building/reviewing)
- Completing a task (→ complete)
- Freezing (→ frozen, include reason)
```

---

## How a Tide Runs (End to End)

### Before (Kiro does this)

1. Decompose the milestone into tasks
2. Group dependent tasks into waves (serial within wave)
3. Verify waves are independent of each other (no cross-wave deps)
4. Size each wave to fit within ~90 minutes of agent work
5. Generate MODULE_MAP.md (file ownership per wave)
6. Create task plan files in `.riptide/plans/` (acceptance criteria in plain English)
7. Initialize `.riptide/status.json` with tide/wave/task structure
8. Set up worktrees: `git worktree add .worktrees/wave-{letter}-{name} -b feature/wave-{letter}-{name}`

### During (Claude Code terminals do this — all waves simultaneously)

Each terminal runs `/sprint {TASK-IDs for this wave}`:
1. For each task in serial order (dependencies flow naturally):
   - `/plan` → read context, write structured plan to `.riptide/plans/{task-id}.md`
   - `/build` → implement from plan, commit
   - `/review` → self-review, write findings to plan file
   - `/compound` → capture learnings
   - Update `.riptide/status.json` at each transition
2. Create PR when wave is complete

### After (You do this)

1. Check dashboard (localhost) for status
2. Review PRs (quick scan — CI should catch real issues)
3. Merge all wave PRs (order doesn't matter — waves are independent)
4. Kick off next tide

---

## What This Saves vs SunForge

| Dimension | SunForge | Riptide |
|-----------|----------|---------|
| Context per agent | ~70KB loaded | <5KB loaded |
| Agents | 5 (including Facilitator) | 4 (Kiro replaces Facilitator) |
| Acceptance criteria | Gherkin (formal) | Plain English |
| TDD enforcement | Every file (hook blocks) | Logic code only (developer judgment) |
| Team coordination | 4-person webhook signals | None (one person watching terminals) |
| File conflict prevention | REGISTRY.json (dynamic) | MODULE_MAP.md (static per tide) |
| Knowledge compounding | Full docs (features, ADRs, patterns, gotchas) | Patterns + gotchas only (<15 lines each) |
| Planning overhead | Interview → PRD → Spec → Issues | Kiro produces issues directly |
| Framework docs | 70KB+ | <15KB total |

---

## Open Questions

1. **Worktree setup** — should `/sprint` create its own worktree, or should worktrees be pre-created by Kiro/bootstrap before terminals launch?
2. **PR strategy** — one PR per wave (all tasks in the wave), or one PR per task? Per-wave is simpler for merge ordering.
3. **Compound timing** — after each task within a wave, or once at the end of the wave before PR?
4. **Tide sizing** — should Kiro enforce the ~90-minute-per-wave budget during decomposition, or is that a guideline?

---

## Tide Budget Constraint

A Claude Code session handles ~90 minutes of actual work. With Riptide's reduced context overhead (~5% vs SunForge's ~50%), effective work time per session is close to the full 90 minutes.

**Rule**: Each wave should be sized to complete within a single Claude Code session (~90 minutes of agent work). Kiro enforces this during decomposition — if a wave's tasks exceed the budget, split into smaller tasks or redistribute across waves/tides.

**A tide** (all waves running in parallel) should complete within one session window. Since waves run concurrently, the tide's wall-clock time equals the longest wave's duration — ideally under 90 minutes.

---

## Commands Summary

| Command | Type | Where It Lives | Purpose |
|---------|------|---------------|---------|
| `bootstrap.sh` | Shell script | Riptide repo (`scripts/`) | Deploy framework into target project |
| `teardown.sh` | Shell script | Riptide repo (`scripts/`) | Remove framework from target project |
| `dashboard.sh` | Shell script | Riptide repo (`scripts/`) | Start localhost status dashboard |
| `/plan` | Claude command | Target project (`.claude/commands/`) | Research + structured plan to `.riptide/plans/` |
| `/build` | Claude command | Target project (`.claude/commands/`) | Implement from plan |
| `/sprint` | Claude command | Target project (`.claude/commands/`) | Batch process tasks in serial order within a wave |
| `/review` | Claude command | Target project (`.claude/commands/`) | Multi-perspective code review |
| `/compound` | Claude command | Target project (`.claude/commands/`) | Capture patterns/gotchas after task completion |

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Bootstrap deploys all template files as regular files

*For any* valid target project path and any set of template files, after the Bootstrap_Script executes, every file in the template directory shall exist at the corresponding path in the target project as a regular file (not a symlink).

**Validates: Requirements 1.1, 1.4**

### Property 2: Bootstrap is idempotent

*For any* target project (whether empty or already containing Riptide files), running the Bootstrap_Script produces the same file state regardless of how many times it is executed, and never produces an error on re-execution.

**Validates: Requirement 1.3**

### Property 3: Teardown preserves project source code

*For any* set of project source files that exist before teardown, running the Teardown_Script shall leave every project source file with identical content, permissions, and path.

**Validates: Requirement 2.4**

### Property 4: Module Map assigns unique file ownership

*For any* valid Module_Map, no file path shall appear in more than one wave's ownership section. The intersection of owned file sets between any two waves is always empty.

**Validates: Requirement 3.1**

### Property 5: Module boundary violation triggers freeze

*For any* file modification attempt where the target file path is not within the executing wave's ownership set (as defined in Module_Map), the module boundary hook shall trigger a freeze and report the conflict.

**Validates: Requirements 3.2, 6.4**

### Property 6: Module Map structural completeness

*For any* wave entry in a valid Module_Map, the entry shall contain a worktree path, a branch name, and at least one owned file glob.

**Validates: Requirement 3.3**

### Property 7: Plan output structural completeness

*For any* plan produced by the Planner_Agent, the plan shall contain: at least one explicit file path, at least one function signature with types, at least one plain English test case, and at least one verification command.

**Validates: Requirements 4.2, 4.3, 4.4, 4.5**

### Property 8: Planner is read-only

*For any* Planner_Agent execution, no source code files shall be created or modified in the working tree.

**Validates: Requirement 4.6**

### Property 9: Kill switch triggers on repeated failures

*For any* sequence of test results where 3 consecutive failures occur on the same test identifier, the Kill_Switch shall trigger a freeze within that wave.

**Validates: Requirements 5.6, 8.1**

### Property 10: Kill switch triggers on stall

*For any* agent execution where elapsed time without a progress marker exceeds 10 minutes, the Kill_Switch shall trigger a freeze.

**Validates: Requirement 8.2**

### Property 11: Freeze halts all work and reports correctly

*For any* freeze event (regardless of trigger), the agent shall: produce no further file modifications or commits, post a message to Linear matching the format "FROZEN: {reason}. Tried: {list}.", and not resume work without an explicit human signal.

**Validates: Requirements 8.3, 8.4, 8.5**

### Property 12: Tester findings have valid severity and critical blocks merge

*For any* finding produced by the Tester_Agent, the finding shall have a severity in {Critical, High, Medium, Low}. For any findings set containing at least one Critical finding, the merge shall be blocked.

**Validates: Requirements 6.5, 6.6**

### Property 13: Sprint processes issues in dependency order

*For any* list of issue IDs with a dependency graph, the Sprint_Command shall process them in an order that is a valid topological sort of that graph.

**Validates: Requirement 9.1**

### Property 14: Sprint executes the correct sequence per issue

*For any* issue processed by the Sprint_Command, the execution sequence shall be exactly: plan, build, review, compound — in that order with no steps skipped or reordered.

**Validates: Requirement 9.2**

### Property 15: Knowledge compound documents are concise

*For any* document created in docs/solutions/ (whether pattern or gotcha), the document shall contain fewer than 15 lines.

**Validates: Requirements 10.1, 10.2**

### Property 16: Commit messages follow the format convention

*For any* commit message produced by the Builder_Agent, the message shall match the format: `{type}: {description} [{ISSUE-ID}]` where type is one of {feat, fix, test, refactor, docs, chore}.

**Validates: Requirement 12.1**

### Property 17: Wave branch names follow the naming convention

*For any* wave worktree branch, the branch name shall match the pattern `feature/wave-{N}-{name}` where N is a positive integer and name is a kebab-case identifier.

**Validates: Requirement 12.2**

---

## Next Steps

1. Resolve open questions
2. Write the actual CLAUDE.md, agent files, and commands
3. Create the repo at `/Users/rholall/Documents/CODE/Riptide`
4. Test with a single wave from the Odoo platform Phase 1
