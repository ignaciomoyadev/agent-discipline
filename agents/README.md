# Agents — source only, deliberately not registered

These seven are **not declared** in `.cursor-plugin/plugin.json`, so Cursor does
not load them from here. That is on purpose.

## Why

Measured 2026-09-09 with an identical canary file in three locations:

| location | registers? | honours `model:`? |
|---|---|---|
| plugin `agents/` | yes | **no — inherits the session model** |
| project `.cursor/agents/` | yes | **yes** |
| user `~/.cursor/agents/` | not in the CLI enum | — |

A canary pinned to `glm-5.2-high` reported Grok in a Grok session and Composer
in a Composer session when the plugin shipped it. The same file at project level
reported GLM 5.2 / Z.ai.

That breaks the cost model these roles exist for: `scout` is pinned to
`composer-2.5[fast=false]` at ~$0.027 a call, and would silently run at whatever
the session costs — up to 8x on a premium model, out of the credits pool rather
than included quota.

## How to use them

Copy into `.cursor/agents/` of each repo, or create them through the Cursor UI.
`AGENTS-PASTE.md` in the lab has every field and body ready to paste.

Keep `[fast=false]` in the model string. A bare slug resolves to the Fast tier:
same model, same effort, roughly 6x the price.

## If a future Cursor version fixes the pin

Add `"agents": "./agents/"` to `plugin.json`. Re-verify with a canary first —
one throwaway agent pinned to a model you are not running, asked to report what
it is. If it reports its pin rather than your session, the fix landed.
