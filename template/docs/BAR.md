# BAR

The standard this project is held to, and the number that says we've met it.

The bar is set by **example** — point at something real, then write down what about it counts,
as values a critic can measure. `/gauntlet` scores work against these metrics and nothing else.

<!-- A design bar and a code-standard bar look nothing alike, and that's fine. What can't vary
     is the frame: named metrics with measured values and fail conditions, a scoring rule, and
     a threshold. Without those, gap scores can't be computed and the loop never terminates. -->

---

## References

What we're holding work up against. Any form — a repo, a URL, a vendored submodule, a doc.
Name the parts that count and the parts that don't.

```
Example:
1. https://github.com/{org}/{repo} — service layer and test structure.
   Specifically `src/services/` and `tests/services/`. The CLI is legacy; ignore it.
2. https://{site} — vendored at `reference/{site}/`. Type scale and interaction density only.
```

<!-- Replace with yours. -->

---

## Metrics

One numbered metric per property that matters. Each needs a **measured value** taken from the
references and a **fail condition** stated concretely enough to disagree with.

"Clean code" is not a metric. "No function exceeds 40 lines" is.

### M1 — {name}
**Measured:** {the value observed in the reference, with units}
**Fails when:** {the concrete condition that constitutes a miss}

### M2 — {name}
**Measured:** {…}
**Fails when:** {…}

<!-- Add M3, M4, M5… as needed. Five is a reasonable ceiling — past that, critics spread thin
     and every round surfaces a different metric. -->

---

## Scoring

Each metric scores **0–10** against its measured value.

```
gap = Σ (10 − score) across all metrics
```

A perfect run is gap `0`. With *n* metrics the worst case is `10n`, so **the threshold has to
move when the metric count does** — a threshold of 8 across 5 metrics is a much tighter
standard than 8 across 10.

**Threshold: 8**

<!-- Set yours. Start looser than feels right and tighten once you've watched a few rounds. -->

Iteration stops when `gap ≤ threshold`.

### If your metrics are binary

Most useful bars are pass/fail — the thing is in the code or it isn't. Score those `10` or `0`,
nothing between. But then read the threshold carefully, because it stops being a quality dial
and becomes a **failure count**:

| Threshold | Failures tolerated |
|-----------|--------------------|
| 0–9       | zero — every metric must pass |
| 10–19     | one |
| 20–29     | two |

A threshold of 8 with binary metrics means **nothing may fail**. That's often what you want;
it's rarely what people expect when they write `8`. Set it to `10 × (failures you'll accept) + 8`.

### Validity

**A critique that cites no measurable reference is invalid and is discarded.** A critic must
point at the metric and the value it missed. This is what keeps the loop measuring the bar
instead of drifting into taste.

---

## Amendments

Critics will sometimes expose a gap in *the bar itself* — a metric that's ambiguous, or one
that's silent where it needed to speak. When work genuinely conflicts with a metric, or a
critic exploits a hole, **amend here with a reason** rather than quietly working around it.

Silent violations are how a standard dies.

```
### {date} — {metric}
**Was:** {original}
**Now:** {replacement}
**Why:** {what forced the change — including "two critics read M2 as permitting X"}
```

<!-- Amendments accumulate below. -->
