# Tasks: Riptide

## Tide 1: Core Framework

### Wave A: Foundation Files

- [x] 1. Create repo structure (`riptide/`, `scripts/`, `template/`, `template/.claude/`, `template/.riptide/`, `template/docs/`, `template/dashboard/`)
- [x] 2. Write `template/CLAUDE.md` — shared agent rules (<1KB)
- [x] 3. Write `template/.riptide/status.json` — initial empty schema
- [x] 4. Write `template/docs/TECH_SPEC.md` — blank template with section headers
- [x] 5. Write `template/docs/MODULE_MAP.md` — blank template with section headers and example

### Wave B: Agent Definitions

- [x] 6. Write `template/.claude/agents/planner.md` — read-only research + plan output (~1.5KB)
- [x] 7. Write `template/.claude/agents/builder.md` — implement from plan, TDD for logic (~2KB)
- [x] 8. Write `template/.claude/agents/tester.md` — multi-perspective review (~1KB)
- [x] 9. Write `template/.claude/agents/debugger.md` — root cause analysis protocol (~1KB)

### Wave C: Commands

- [x] 10. Write `template/.claude/commands/plan.md` — /plan {TASK-ID}
- [x] 11. Write `template/.claude/commands/build.md` — /build {TASK-ID}
- [x] 12. Write `template/.claude/commands/sprint.md` — /sprint {TASK-IDs...}
- [x] 13. Write `template/.claude/commands/review.md` — /review
- [x] 14. Write `template/.claude/commands/compound.md` — /compound

### Wave D: Hooks + Settings

- [x] 15. Write `template/.claude/hooks/kill-switch.sh` — freeze on 3 failures or 10min stall
- [x] 16. Write `template/.claude/hooks/module-boundary.sh` — warn/freeze on cross-module writes
- [x] 17. Write `template/.claude/hooks/block-dangerous-git.sh` — prevent force push, reset --hard, etc.
- [x] 18. Write `template/.claude/settings.json` — hook registration config

---

## Tide 2: Scripts + Dashboard

### Wave E: Bootstrap & Teardown

- [x] 19. Write `scripts/bootstrap.sh` — deploy template into target project, init .riptide/, update .gitignore
- [x] 20. Write `scripts/teardown.sh` — remove all Riptide artifacts from target project
- [x] 21. Write `scripts/dashboard.sh` — start localhost server for dashboard

### Wave F: Dashboard

- [x] 22. Write `template/dashboard/index.html` — single-file status dashboard (implement from pen file design)

### Wave G: Documentation + Testing

- [x] 23. Write `README.md` — what Riptide is, quick start, command reference
- [x] 24. Test bootstrap: run `bootstrap.sh` against a fresh test directory, verify all files deployed
- [x] 25. Test teardown: run `teardown.sh` against bootstrapped directory, verify clean removal
- [x] 26. Test idempotence: run `bootstrap.sh` twice, verify no errors or duplicates
- [x] 27. Dry-run: bootstrap into a dummy project, run `/sprint` with a mock task, verify status.json updates
