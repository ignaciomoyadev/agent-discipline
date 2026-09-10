---
name: token-discipline
description: Route work across the delegated agent fleet (scout, researcher, builder, surgeon, auditor, scribe) and keep context cheap. Use when a task is large enough to split, when exploration would flood the main context, or when deciding which model tier a piece of work deserves.
color: cyan
---

# Token discipline

Cost is set by how work is routed, not by how tersely the answer is written.
Terseness caps output tokens; routing caps everything else. Both matter, in that
order.

## Route before you work

Ask two questions about any unit of work:

1. **Does the answer need to enter my context, or only its conclusion?**
   Exploration, search, doc-reading and log-trawling produce a lot of tokens and
   a small conclusion. Delegate those and keep the conclusion.
2. **How much reasoning does this actually need?**
   Locating a symbol needs none. Diagnosing a race needs a lot. Paying the top
   tier for a `grep` is the most common waste in an agent system.

| Work | Agent | Model | Mode |
|---|---|---|---|
| Locate files, symbols, callers, prior art | `scout` | `composer-2.5` | foreground |
| Sweep a codebase for defects | `hunter` | `composer-2.5` | background |
| Read external docs, confirm versions and APIs | `researcher` | `grok-4.6[medium]` | background |
| Implement a settled design | `builder` | `composer-2.5` | foreground |
| Annotate doubt on work that matters | `auditor` | `composer-2.5` | foreground |
| Compress a long transcript or dump | `scribe` | `composer-2.5` | background |
| Hard bug where a cheap pass already failed | `surgeon` | `grok-4.6[xhigh]` | foreground |

## Do not chain an agent that already opens files

`hunter`, `builder`, `auditor` and `surgeon` read the workspace themselves. Sending
`scout` ahead of them is a call you pay for and nobody uses.

`scout` answers "where is X". It earns its place when **you** need coordinates to
decide what to do next — not as a warm-up for an agent whose own first
instruction is to read every relevant file.

The same logic runs the other way: do not ask `scout` for an exhaustive
inventory. It is capped at 15 rows and built to locate, not to enumerate.
Observed on a real addon: asked for a model's location *and* all its computed
fields, it nailed the location and listed the fields of one model only. That is
the role working as written, not failing.

## Escalate on evidence, never on suspicion

Reach for `surgeon` only after a cheaper pass has actually failed or returned
something genuinely knotty. A `surgeon` run that a `scout` could have answered
costs roughly an order of magnitude more for the same answer.

This is about *sequencing after a result*, not about chaining agents up front.
Escalation is a decision you take once the cheap tier reports back; the section
above is about not paying for a step nobody consumes.

## Read a defect sweep by severity

`severity: high` is the one field measured to predict whether a finding is real:
**0.978 precision in `hunter`, 0.953 in a variant, across 206 graded findings.**
Everything below it sits near 0.73.

So a sweep arrives with a reading order, not just a list:

- `high` — treat as real. Fix it, or hand it to `surgeon` if the fix is knotty.
- `medium` / `low` — about three in four hold up. Worth a cheap second look, not
  worth escalating on sight.

This is the concrete form of the rule above: **severity is the evidence.**

Do not add a confidence score to sharpen it. Measured: self-reported confidence
does not separate real findings from false ones (gap 0.048 against a spread of
0.086), and asking for the field cost 11.5 pp of recall even though the format
came back perfect 95 times out of 95. A richer output contract does not fail by
arriving malformed — it fails by spending the model's attention on the format
instead of on the code.
## Keep the prefix stable

Everything a provider can cache is priced at a small fraction of fresh input.
That makes prefix stability worth more than prompt brevity:

- Put stable content first — kernel, role prompt, tool schemas
- Put volatile content last — the brief, the current state
- Never inject a timestamp, a run id, or a shuffled list into the prefix. One
  changed byte early in the prompt invalidates everything after it.

Rewriting a system prompt on every call to save fifty tokens can cost more than
it saves, by breaking the cache on thousands.

## Offload instead of truncating

When a result is large, write it to a file and return the path plus a digest.
The orchestrator reads the digest; it opens the file only if it must. Truncating
loses information at the same price. Offloading keeps it at a lower one.

The same logic governs this skill: keep `SKILL.md` short and push detail into
`references/`, so the body loads only when the task matches.

## Compact history, do not replay it

Replaying a full transcript every turn makes cost grow with the square of turn
count. Fold settled history into a checkpoint — decisions made, state reached,
questions still open — and keep only recent turns verbatim. `scribe` exists for
this.

## Do not pay twice for failure

Classify a failure before retrying it. A wrong tool argument is worth one retry;
a wrong plan is not — it wants a new plan. Identical failing calls in a row mean
stop, not try harder.

## Writing rules that stay cheap

Content in `AGENTS.md` or an always-applied rule is in context on every single
turn, for every task, whether or not it is relevant. Content in a skill enters
context only when its description matches the work.

So: put the handful of things that are true for *all* work in rules, and put
everything else in skills. A large always-on rules file is the most common
avoidable cost in a Cursor setup.
