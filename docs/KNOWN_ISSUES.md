# Known Issues

Open defects and unverified assumptions in Riptide. Update as these get confirmed or fixed.

---

## 1. Channel enforcement hook is currently inert

**Status:** Confirmed by code reading. Not yet fixed.
**File:** `template/.claude/hooks/cross-channel.sh:37-48`

The hook derives the current wave from the git branch name, expecting the format
`feature/wave-{N}-{name}`. If it can't find a `wave-` token it exits 0 (allow).

Nothing in `template/CLAUDE.md` or the shipped slash commands instructs an agent to create a
`feature/wave-*` branch. The worktree convention added in `2627cf6` is ticket-based
(`.worktrees/{TICKET-ID}`). On a ticket branch, `CURRENT_WAVE` resolves to empty and **every
write is allowed**.

Net effect: `CHANNELS.md` is maintained but not enforced.

**Fix direction:** either derive the wave from `.riptide/status.json` rather than the branch
name, or settle the branch-naming convention and make the commands enforce it. This is
entangled with the open question of whether native Plan Mode should own boundary declarations
(see issue 4).

---

## 2. `jq` missing silently disables enforcement

**Status:** Confirmed by code reading. Not yet fixed.
**File:** `template/.claude/hooks/cross-channel.sh:14-16`

If `jq` isn't on PATH the hook exits 0. `jq` ships by default on neither macOS nor Windows,
so a fresh machine gets no boundary enforcement and no warning that it's missing.

`kill-switch.sh` should be audited for the same pattern.

**Fix direction:** fail closed, or at minimum emit a visible warning once. Silent full bypass
is the wrong default for a safety mechanism.

---

## 3. Absolute vs. relative path mismatch in glob matching

**Status:** Confirmed by code reading. Not yet fixed. Masked by issue 1.
**File:** `template/.claude/hooks/cross-channel.sh:91`

`tool_input.file_path` arrives as an absolute path. `CHANNELS.md` globs are relative
(`src/api/**`). The comparison is `grep -qE "^$PATTERN"` — anchored at the start of the
string, so an absolute path can never match a relative glob.

Once issue 1 is fixed and wave detection starts succeeding, this flips the hook's failure mode
from allow-everything to **block-everything**. Fix the two together.

**Fix direction:** normalize `FILE_PATH` to a project-relative path before matching.

---

## 4. Boundary source of truth is unsettled

**Status:** Open design question.

Planning moved to Claude's native Plan Mode (`55bfb6e`), but `CHANNELS.md` is still a
separate hand-authored artifact. Options considered: keep the standalone map, or have each
approved plan at `.riptide/plans/{wave-id}.md` declare its own owned paths in frontmatter and
have the hook read that.

Deferred pending real-world use of Plan Mode. Issues 1 and 3 should probably be fixed in
whichever direction this lands.

---

## 5. Windows support unverified

**Status:** Unverified. To be investigated on the Windows machine.

Riptide is used on both macOS and Windows. The following are **suspected** problems, flagged
from code reading on macOS but not reproduced:

- **Hook invocation.** `template/.claude/settings.json` invokes hooks as
  `"$CLAUDE_PROJECT_DIR"/.claude/hooks/foo.sh` — POSIX variable syntax, with `#!/bin/bash`
  shebangs. Fine under Git Bash / MSYS (which `scripts/bootstrap.sh:49` confirms is in use).
  Unknown whether Claude Code on Windows dispatches hook commands through Git Bash or
  `cmd.exe`. If the latter, none of the three hooks fire.
- **Path separators.** Windows `file_path` values use backslashes (`C:\Users\...`). The glob
  matching in `cross-channel.sh` assumes forward slashes, so it cannot match. This one is a
  near-certain bug rather than a suspicion.
- **`jq` availability.** See issue 2 — less likely to be present on Windows.

**Next step:** verify hook dispatch on the Windows box first. That answer determines whether
the rest is a porting job or a rewrite (e.g. moving hooks to Node, which Claude Code already
requires on both platforms).

---

## Common thread

Every failure mode in `cross-channel.sh` is **fail-open and silent**. A missing `jq`, an
unrecognized branch name, an unparsed path, or a hook that never executes all produce the same
observable result: no freezes, no output, work proceeds. There is no signal distinguishing
"channels enforced, nothing violated" from "enforcement disabled entirely."

Worth addressing as its own concern, independent of the individual bugs.

**The one deliberate exception** is the plan approval gate. `/surf` phase 0 and `/build` both
refuse to proceed when a wave plan is missing or lacks its `**Approved**:` line, and refuse to
generate one when no human is present. That gate fails *closed* on purpose — an unreviewed
plan executed unattended is the failure this design exists to prevent. Any future change to
the hooks should move them toward that behavior, not the reverse.

---

## 6. `jq` may be uninstallable in locked-down environments

**Status:** Open, environment-dependent.

Riptide is used on a work machine without administrative privileges — part of why it's
markdown-and-bash rather than an installed toolchain. But `cross-channel.sh` hard-depends on
`jq`, which may be impossible to install there, and issue 2 means its absence is silent.

Combined, that's the worst case: the one environment where riptide's lightness matters most is
also the one most likely to run with enforcement quietly disabled.

**Fix direction:** replace `jq` usage with something universally available, or fail loudly at
bootstrap so the gap is known at deploy time rather than discovered never.
