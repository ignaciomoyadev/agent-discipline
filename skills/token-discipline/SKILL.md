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

| Work | Agent | Model tier |
|---|---|---|
| Locate files, symbols, callers, prior art | `scout` | `effort=low` |
| Read external docs, confirm versions and APIs | `researcher` | `effort=medium` |
| Implement a settled design | `builder` | `effort=high, fast` |
| Hard bug, tangled refactor, a cheap pass already failed | `surgeon` | `effort=xhigh, fast` |
| Adversarially verify work that matters | `auditor` | `effort=xhigh` |
| Compress a long transcript or dump | `scribe` | `composer-2.5` |

Escalate on evidence, never on suspicion. Send `scout` first; promote to
`surgeon` when the cheap pass returns something genuinely knotty. A `surgeon`
run that a `scout` could have answered costs roughly an order of magnitude more
for the same answer.

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
