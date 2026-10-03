# ICM and the Gauntlet Loop

Background reference so a fresh session does not have to go research these.
Not a spec. The decisions that act on this live in `docs/specs/riptide-v2/brief.md`.

Three things are kept separate below, because conflating them causes errors:

- **As published** — the ICM paper.
- **As practised** — the working LookML implementation these notes are drawn from.
- **As decided for v2** — where Riptide deliberately departs.

---

## ICM (Interpretable Context Methodology)

**Source:** "Interpretable Context Methodology: Folder Structure as Agent
Architecture," Van Clief and McDermott (Eduba / University of Edinburgh),
arXiv 2603.16021v2.

### The core claim

Orchestrate agent workflows with folder hierarchies and markdown files instead of
a multi-agent framework. Numbered folders carry sequencing, hierarchy carries
context scoping, plain files carry state. One agent reads the right files at the
right moment.

The reported payoff is context economy: stage-scoped loading of roughly 2,000 to
8,000 tokens per stage against ~40,000 for a monolithic approach. Secondary
claims: non-technical users could modify workflows by editing markdown, and
practitioners show a U-shaped intervention pattern, editing heavily at the first
and last stages and lightly in the middle.

### The five layers

| Layer | Question it answers | Where it lives |
|---|---|---|
| L0 | Where am I? | `IDENTITY.md`, `CLAUDE.md` |
| L1 | Where do I go? | `CONTEXT.md` (routing) |
| L2 | What do I do? | `stages/NN-*/CONTEXT.md` (the control point) |
| L3 | What rules apply? | `_config/`, `shared/`, stage `references/` |
| L4 | What am I working with? | `stages/NN-*/output/` |

### Two structural ideas worth knowing

**Catalog versus payload.** L0 through L2 are the catalog: small, stable, and
carrying no work product. A *routing file* tells you where to go rather than
holding the thing you are going for. If a routing file is growing, it is absorbing
payload, and the payload should move to a shelf in L3 with a link left behind. A
table of contents that starts explaining things has become a chapter.

**Factory versus product.** The factory is the apparatus that does the work and is
stable across runs: `_config/`, `shared/`, each stage's `references/`. The product
is new every run: the run-brief copy and each `stages/NN-*/output/`. Note that
both context and encoded expertise are *factory*. Nothing about this split maps
onto them.

### Working shape

A workspace has a **form**. The one in use is `pipeline`: the same sequence runs
repeatedly and a deliverable leaves each run.

Four verbs, as implemented: `icm stage` adds a step, `icm sync` refreshes routing,
`icm run` walks the workspace, `icm audit` validates before finishing.

Every output is an edit surface. The run stops at a human check, a person edits,
and the agent reads whatever they left. As practised, a stage is COMPLETE when its
`output/` holds a file other than `.gitkeep`.

---

## The gauntlet loop

A reusable validation pattern, invoked at the end of **every** stage rather than
once at the end of a run. Score that stage's output against that stage's own bar
using blind critics before moving on.

The rationale for per-stage: a single final pass finds every stage's defects at
once with no attribution back to which stage introduced which, and by then four or
five stages of work may be sitting on top of the actual mistake.

### Critic rules

Each critic gets exactly four things: the goal in one paragraph, the stage's bar,
the applicable rules, and the artifact as it currently stands.

**Never give a critic the build history.** No plan, no commit log, no diff, no
previous round's findings. A diff reveals how it was built; current state does not.
A critic who knows how you tried will grade the attempt instead of the result.
Fresh critics every round, and never summarise a previous round into a new prompt.

Where possible, give critics read-only warehouse access. A critic that can run SQL
checks the artifact's claims instead of trusting them. Every number in a comment,
description or text tile is a claim, and a wrong one is a finding.

### What counts as a finding

Three required fields: **evidence** citing `file:line`, **probable cause** citing
`file:line`, and a **concrete fix with numeric values**. A finding citing no
measurable reference from the bar is invalid and discarded.

> Invalid: "improve the documentation."
> Valid: "`dim_detail.semantic.view.lkml:31` sums 132 rows totalling 6,730.95
> against a source population of X; add that figure to the description."

Critics rank by impact divided by cost, and additionally weight **whether the
builder can verify the finding**. An untestable finding outranks a testable one of
equal impact, because untestable is exactly where the builder's judgment is worth
least.

### Fix cadence

One fix per round, then re-score. Applying everything at once makes the next
round's score unattributable.

Switch to batch-fixing once the backlog is known and material. One-per-round is
right while *discovering* whether the bar is met; it becomes the bottleneck once
several real defects are listed and the round cap is small. Record which mode you
are in and why.

### Amending the bar

Two critics reading the same hole the same way is the signal. Amend in the open
with the reason recorded.

**Never lower a threshold to pass.** A threshold quietly moved is a failure with
better paperwork. Amending *where* a requirement points is legitimate; amending
*whether* it applies is not. Watch for a metric that fails for missing prose
rather than for a defect. Metrics should fail for defects.

### Exits

| Exit | Condition |
|---|---|
| **PASS** | Gap at or below threshold. The only success exit. |
| **PLATEAU** | Gap flat two consecutive rounds *and* a critic majority names the same metric unreachable. Never declarable on round 1. |
| **FREEZE** | Gap rising, or flat with critics disagreeing on cause, or round cap hit. |

A plateau is observed, never predicted. One critic forecasting a ceiling is a
guess, and acting on it lets the loop talk itself out of work.

### Known limits

The loop reads the artifact and queries the warehouse. **It cannot compile.** On
the reference build, every error class that shipped survived blind review and SQL
verification, then surfaced in seconds once the target platform parsed the
project.

So a PASS is not "done." It means "ready for the human gate," and the gate
includes loading the work into the real system. How that gate happens is a
per-run detail, not a factory rule.

Related open question, deliberately unanswered: one gate is demonstrably
insufficient, but the evidence only shows *more than one*, not how many or which.
Gate design is its own conversation.

---

## Where v2 departs from ICM as published

Two deliberate changes. Both are decisions, not open questions.

1. **Folders carry instructions; frontmatter carries state.** Ordered stage
   directories stay, for sequence, scoping and small per-stage token loads.
   Artifacts stop moving between folders to record status. Status, run id and gate
   results live in frontmatter, which makes the catalog a rendered view rather
   than a location.
2. **Workstream, not workspace.** "Workstream" is the term used throughout
   Riptide v2 for what ICM calls a workspace. A wave executes one.

See `docs/specs/riptide-v2/brief.md` for the rest, including the two-location
structure and the knowledge-addressing decisions.
