# Brief: Riptide v2 — Workstreams

Date: 2026-09-05
Background: `docs/icm-and-gauntlet.md` — read first if ICM or the gauntlet loop are unfamiliar.

## What changes

v1 orchestrates concurrent agents through waves. v2 keeps that and adds a reusable
unit of encoded method: the **workstream**. Riptide stops being a place where work
lives and becomes the thing that runs work defined elsewhere.

## Glossary delta

v1's glossary needs two edits. (It also still names Linear as the coordination bus,
which `design.md` already dropped. Fix while in there.)

- **Tide** — unchanged. A collection of independent waves running in parallel.
- **Wave** — the schedulable unit or work. Either carries explicit ad-hoc serial tasks, or names a  
single workstream to execute. Waves stay concurrent within a tide.
- **Workstream** *(new)* — a reusable, ordered pipeline of stages with per-stage
contracts. The method. Lives outside this repo.

Wave is the run. Workstream is the method. Do not collapse them.

## Two locations

Riptide is cloned. It points at exactly one external root via a configured path.
That root holds three directories:


| Directory      | Holds                                |
| -------------- | ------------------------------------ |
| `global/`      | Foundational context spanning epics  |
| `planning/`    | `epics/` and `sprints/`              |
| `workstreams/` | Workstream definitions (ICM folders) |


Nothing in that root ships with Riptide. Workstreams are the operator's portable  
work product and may be private; project context belongs to the organization.  
Riptide itself stays public and contains no domain content.

## Workstream structure

Adopts ICM's five-layer scheme (identity, routing, stage contract, reference,
output), with two deliberate departures:

1. **Folders carry instructions. Frontmatter carries state.** Ordered stage
 directories give sequence, scoping and small per-stage token loads. Artifacts
 never move between folders to record status. Status, run id and gate results
 live in frontmatter, so the catalog is a rendered view rather than a location.
 
2. **The gauntlet runs at the end of every stage, not once at the end.** May need to look up gauntlet loops. A single final pass gives no attribution and buries defects under later work. 

Workstreams must be referenceable from `CLAUDE.md` files and skills, so the path
config has to resolve for both.

## Knowledge addressing

One gap in three forms: "no system for where knowledge lives, what it claims, and which version wins." 



**Where it lives.** Nothing records ticket to repo to worktree. A review target  with the ticket number and no repo or branch sent the`code-review` skill through a `git log --all` sweep and a 95k-file glob (A3). A fresh thread already anchored inside a stale worktree searched the wrong repo and  
returned "nothing found," which read as a real negative result (A4). v2 needs an explicit map from ticket to repo, branch and working location, and skills must  
read it rather than infer it from convention. This can be stored in the domain knowlege at the root files referenced above, under planning. 

**Routing.** Designating a location does not route anything to it.
`.riptide/docs/solutions/` held one `.gitkeep` for an entire sprint while rule 8
checked it empty before every implementation, and every pattern the sprint
produced landed in whichever folder the writer was already in (B6). This applies
directly to `global/`, `planning/` and `workstreams/`, which are three more  
designated locations. A location with no step that writes to it is decoration. Basically, we are deprecating `.riptide/docs/solutions/` and writing solutions to the planning directory.

**Provenance.** Form does not signal authority. A derived shopping list reads
exactly like a spec, tables of dimensions and measures, so it was treated as one.
Its invented `rejection rate = rejections / attempts` produced a grain-tension analysis, three proposed architectural options and a TRD gap entry, all resolving  
a requirement no ticket ever made. Three further instances the same sprint (Part 1 §4). Documents declare in frontmatter whether they are primary or derived,  
what they derive from, whether their contents are verified or guessed, and whether they are current or superseded and by what. 



## Dashboard

No change needed. `template/dashboard/index.html` (456 lines, no dependencies)
polls `.riptide/status.json`; `scripts/dashboard.sh` serves it on localhost.
Repoint at the new structure. Do not add a framework.

## Scheduling

**Hooks for what is inside the repo. Schedules for what is outside it.** Developer
work is demand-driven, so most automation is event-triggered. Use `launchd` rather
than cron on macOS: a missed cron job is skipped, `launchd` runs it on wake.

Two worked examples of the split:

- Pull latest and confirm branch is **step one of the workstream**, called as a
skill. Not scheduled.
- Detecting that upstream moved is **outside your control**, so it is scheduled.

First proof of concept: every 30 minutes during work hours, `git fetch` across
configured project repos and write which have moved ahead into `.riptide/status.json`.
Roughly ten lines, no external service, no account, no admin rights, and it renders
in the existing dashboard with no new UI.

## Constraints (these are the product)

- Install is `git clone`. Nothing more.
- Assume no admin credentials on the target machine.
- No VPS, no hosted service, no account.
- Multi-repo always. Riptide sits outside project repos.
- Audience is developers. GitHub is the distribution surface.
- Stay small. Current repo is 812K.

## Out of scope

- **Composio.** Below their top tier they hold the OAuth credentials, which means
vendor review and a DPA for corporate tokens. Fails the clone-only constraint.
Use sanctioned CLIs, an approved MCP server, or direct API calls instead.
- **Model routing.** The employing organization dictates the account.
- **Paperclip / Mission Control.** Both need infrastructure Riptide cannot assume.
- **Slack integration.** Correct instinct (it changes without you) but a Slack app
needs workspace admin approval. Same wall as Composio.
- **Editing existing workstreams.** The LookML workstream is an application of
Riptide, not part of it.

## Open

- Where the path config lives (`.riptide/` config file vs environment variable).
- The provenance frontmatter field set.
- What performs routing: a step in each stage contract, a hook, or a skill.
- Where the ticket to repo/branch/worktree map lives, and who writes it.
- Whether Riptide ships a skill to scaffold and QA a workstream.
- v1 `requirements.md` still references Linear.

