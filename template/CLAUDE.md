# CLAUDE.md

## Rules
0. Check `.riptide/status.json`'s `mode` field (`single-repo` or `multi-repo`) before touching
   MODULE_MAP.md — it tells you which wave format (worktree vs. repo-scoped) applies.
1. Read task plan before starting work.
2. Stay within module boundary (MODULE_MAP.md). In multi-repo mode, "boundary" includes the
   repo, not just the path — a glob owned in `repo-a` says nothing about `repo-b`.
3. Logic: test first. Declarative: write directly.
4. Atomic commits, one concern each.
5. 3 failures same test → FREEZE, update status, stop.
6. 10min stuck → FREEZE, update status, stop.
7. Follow the plan. No architecture decisions.
8. Check docs/solutions/ before implementing.
9. Capture patterns/gotchas in docs/solutions/ after.
10. Update .riptide/status.json on transitions.

## Context Order
CLAUDE.md → TECH_SPEC.md → MODULE_MAP.md → docs/solutions/ → .riptide/plans/{task-id}.md

## Roles
/plan — read-only research, output to .riptide/plans/
/build — implement from plan (TDD logic, direct declarative)
/review — code review, findings to plan file
/compound — capture patterns/gotchas

## Commits
{type}: {desc} [{TASK-ID}]
Types: feat|fix|test|refactor|docs|chore

## Status
Write .riptide/status.json: start→planning/building/reviewing, done→complete, freeze→frozen+reason
