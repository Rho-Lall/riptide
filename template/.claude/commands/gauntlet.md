---
description: Run the gauntlet — blind critics score the wave's work against the bar, iterate until gap ≤ threshold
---

# /gauntlet

Score finished work against `docs/BAR.md` using critics that know nothing about how it was
built, then fix the largest gap and go again. Stop when the gap score reaches the threshold.

Runs **at wave completion**, once the wave's tickets are all built and verified — not per
ticket. The bar describes the finished thing, and a half-built chain fails metrics it was never
going to meet mid-wave.

## Usage

```
/gauntlet
/gauntlet --round-cap {N}     # default 4
```

## What the critics get

Each critic receives exactly four things:

1. **The goal** — what this wave was meant to achieve, one paragraph. Without it a critic can't
   tell "this is missing" from "that was never in scope," and burns rounds on both.
2. **`docs/BAR.md`** — the references, the metrics, the scoring rule
3. **The relevant rules** — `docs/TECH_SPEC.md` constraints that apply
4. **The artifact in its current state** — the files as they now exist

What critics **never** get is the builder's history or reasoning: no plan, no commit log, no
diff, no earlier round's findings. A diff reveals the build; current state doesn't. Every round
spawns new critics with fresh context — never reuse one, and never summarize a previous round
into a new one's prompt.

The line is between *what was asked for* (the critic needs it) and *how it was attempted* (the
critic must not see it). A critic that knows how you tried will grade the attempt instead of
the result.

Where the bar is a reference you can put side by side with the work — a page, a rendered
output — present both **unlabeled** and have the critic compare blind. Do this whenever the
artifact form allows it.

## Steps

### 1. Check readiness

- All tickets in the wave are `complete` in `.riptide/status.json`.
- `docs/BAR.md` has at least one metric and a threshold. If it doesn't, stop and say so —
  there's nothing to score against.

Update status to `"reviewing"`.

### 2. Spawn blind critics

Spawn **3 critics in parallel**, each a fresh-context subagent. Give each one this brief —
and nothing beyond the four inputs above:

> Here is the goal this work was meant to achieve: {goal}.
>
> You have no information about how it was built and must not speculate about the process.
> Judge the result, not the attempt.
>
> Read `docs/BAR.md`. Score the artifact on **every** metric, 0–10 against that metric's
> measured value. Then rank the gaps you found by **impact ÷ cost** — how much closing it
> moves the score, divided by how much work it takes.
>
> Report the ranked list, largest first. Every gap needs all three fields:
>   1. **Evidence** — what in the artifact misses, citing file:line
>   2. **Probable cause** — the specific place responsible, file:line
>   3. **Concrete fix** — with numeric values
>
> Vague findings are invalid and will be discarded. "Improve the error handling" is not a
> finding. "`parseOrder` at order.ts:42 throws on malformed input where M2 requires returning
> a typed error; wrap in a Result and return `{ok:false}`" is. A critique citing no
> measurable reference from the bar is invalid — do not submit one.
>
> Output:
>   SCORES: M1={n} M2={n} …
>   GAP: {sum of (10 − score)}
>   RANKED:
>     1. {metric} — evidence / cause / fix        (impact {n}, cost {n})
>     2. {metric} — evidence / cause / fix        (impact {n}, cost {n})
>     …
>   CEILING: {none | metric(s) you judge unreachable, and why}
>
> For CEILING, only name a metric if closing it is genuinely outside this work's reach —
> it needs a decision, a dependency, or a change you cannot make here. Difficulty is not
> unreachability. If you can describe a concrete fix, it is reachable; say `none`.

### 3. Aggregate

Gap score for the round is the **median** of the critics' gap scores — a median resists one
critic scoring oddly without letting a lenient one carry the round.

Record every round in the wave plan under `#### Gauntlet`:

```markdown
#### Gauntlet

**Round {n}** — gap {median} (critics: {g1}, {g2}, {g3})
- Scores: M1={n} M2={n} …
- Top gap: {metric} — {evidence / cause / fix}
- Applied: {what changed}
- Regression: {none | metric that dropped, and what was reverted}
```

### 4. Decide

- **gap ≤ threshold** → **PASS**. Record the final score and stop.
- **gap > threshold** → apply the **top-ranked gap only**, then return to step 2 with new
  critics.

Critics report the full ranked list; you act on one item. Applying every finding at once makes
the next round's score unattributable, and the loop stops teaching you anything. The rest of
the list isn't wasted — it's the standing backlog, and the next round re-ranks it against a
changed artifact anyway.

### Regression check

Before accepting a round's fix, confirm it didn't break something that previously passed:
compare this round's per-metric scores against the last round's. Any metric that dropped is a
regression — report it explicitly and revert the fix rather than carrying it forward.

"No regression" is a valid and expected result. Don't manufacture one.

### 5. Amend the bar when the bar is what's wrong

Sometimes critics converge on something the bar got wrong — a metric that's ambiguous, or
silent where it needed to speak. Two critics reading the same hole the same way is the signal.

When that happens, **amend `docs/BAR.md`** with the reason and carry on. Do not silently
violate a metric, and do not loosen a threshold to make a round pass. Amendments are part of
the record; a threshold quietly moved is just a failure with better paperwork.

## Stopping

**PASS** — `gap ≤ threshold`. The only success exit.

Otherwise, four ways this ends. All of them stop the loop and hand back to a human; none of
them is a pass.

### PLATEAU

The gap has held at the same value for **two consecutive rounds**, and a majority of this
round's critics named the same metric(s) under `CEILING`.

That combination means the standing gaps aren't closable by more rounds — the score has stopped
moving *and* independent critics agree on why. Further rounds spend critics to learn nothing.

Exit with:

```
PLATEAU at gap {n} (threshold {t})
Stuck: {metric} — {why critics judge it unreachable}
Rounds: {n1} → {n2} → {n3}
Recommend: {amend the bar | new ticket for the blocker | accept the ceiling}
```

Set `.riptide/status.json` to `"frozen"` with the reason prefixed `PLATEAU:` so it's
distinguishable from a failure at a glance.

**A plateau is observed, never predicted.** One critic forecasting "we'll top out around 7" is
not a plateau — it's a guess, and acting on it lets the loop talk itself out of work. Two
rounds of flat score plus converging critics is evidence. Nothing less qualifies.

You may not declare PLATEAU on round 1. There is no trend yet.

### FREEZE

- **Gap increasing** → freeze immediately. Something regressed.
- **Gap flat but critics disagree on the cause** (no CEILING majority) → freeze. The fixes
  aren't landing, which is a different problem from an unreachable bar.
- **Round cap reached** (default 4) → freeze. Report the trend and the standing largest gap.

On any freeze: update `.riptide/status.json` to `"frozen"` with the reason, and stop.

Don't keep spending critics on a loop that isn't converging, and don't convert a freeze into a
plateau to close out the wave.

## Rules

- Critics get the goal, the bar, the rules, and the artifact — never the builder's history.
- Fresh critics every round. No memory across rounds.
- Rank by impact ÷ cost; act on the top item only.
- Every gap needs evidence, probable cause, and a concrete fix with numbers.
- No measurable reference, no finding. Vague critiques are discarded.
- Compare blind and unlabeled wherever the artifact form allows.
- Never lower the threshold to pass. Amend the bar in the open or freeze.
- PLATEAU requires two flat rounds *and* critic agreement. It is an exit, not a pass.
