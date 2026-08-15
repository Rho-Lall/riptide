# CLAUDE.md

## Rules
0. Check `.riptide/status.json`'s `mode` field (`single-repo` or `multi-repo`) before touching
   CHANNELS.md — it tells you which wave format (worktree vs. repo-scoped) applies.
1. Read task plan before starting work.
2. Stay in your channel (CHANNELS.md). In multi-repo mode, a channel includes the repo, not
   just the path — a glob owned in `repo-a` says nothing about `repo-b`.
3. Logic: test first. Declarative: write directly.
4. Atomic commits, one concern each.
5. 3 failures same test → FREEZE, update status, stop.
6. 10min stuck → FREEZE, update status, stop.
7. Follow the plan. No architecture decisions.
8. Check docs/solutions/ before implementing.
9. Capture patterns/gotchas in docs/solutions/ after.
10. Update .riptide/status.json on transitions.

## Context Order
CLAUDE.md → TECH_SPEC.md → BAR.md → CHANNELS.md → docs/solutions/ → .riptide/plans/{wave-id}.md

## Roles
/plan-sprint — triage a ticket set into waves (orchestrator terminal, upfront)
plan-ticket skill — produce a wave's plan in native Plan Mode, human approves. No /plan command.
A wave must have an approved plan at .riptide/plans/{wave-id}.md before /build runs — approved
means the plan carries an `**Approved**:` line. Never write that line yourself.
/surf — run one wave: plan, build each ticket, then gauntlet at the end
/build — implement from plan (TDD logic, direct declarative)
/gauntlet — blind critics score the wave against docs/BAR.md, iterate to threshold (wave end)
/compound — capture patterns/gotchas

## Commits
{type}: {desc} [{TASK-ID}]
Types: feat|fix|test|refactor|docs|chore

## Status
Write .riptide/status.json: start→planning/building/reviewing, done→complete, freeze→frozen+reason

## Worktrees
Ticket work happens in a git worktree at `.worktrees/{TICKET-ID}` relative to this repo's
root, created by the orchestrator session (a separate Claude session with git ability — git
actions are locked down here). If you're working on a specific ticket, `cd` into
`.worktrees/{TICKET-ID}` first — don't work from the main checkout. If that worktree doesn't
exist yet, tell the human/orchestrator to create one rather than attempting `git worktree`
yourself.
