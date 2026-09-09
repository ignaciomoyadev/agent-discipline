#!/bin/sh
# beforeReadFile -- keep secrets out of the context window.
#
# Two wins from one hook. Credentials never reach a model provider. And a read
# .env or lockfile sits in context for the rest of the session, re-sent and
# re-priced on every turn while being useful on approximately none of them.
#
# POSIX sh, no external dependencies. Contract: JSON on stdin, JSON on stdout,
# exit 0. A malformed response is silently treated as "allow", so every path
# here must print valid JSON.

set -u

emit_allow() { printf '{"permission":"allow"}\n'; exit 0; }

emit_deny() {
  printf '{"permission":"deny","user_message":"guard-read blocked a credential file: %s","agent_message":"Reading %s is blocked -- it holds credentials. Do not attempt a workaround such as cat, grep, or a shell redirect. If you need a value from it, ask the user for the specific key by name."}\n' "$1" "$1"
  exit 0
}

emit_warn() {
  printf '{"permission":"allow","agent_message":"%s is a generated or vendored file. It is large and will stay in context for the rest of this session. Read it only if the task genuinely depends on its contents; prefer grep for a single fact."}\n' "$1"
  exit 0
}

trap 'printf "{\"permission\":\"allow\",\"user_message\":\"guard-read errored; read allowed\"}\n"; exit 0' HUP INT TERM

input=$(cat 2>/dev/null) || emit_allow
[ -n "$input" ] || emit_allow

path=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\(\(\\.\|[^"\\]\)*\)".*/\1/p' 2>/dev/null)
[ -n "$path" ] || emit_allow

p=$(printf '%s' "$path" | sed 's/\\\\/\//g')
leaf=$(printf '%s' "$p" | sed 's|.*/||')

# --- secrets: hard deny -----------------------------------------------------
if printf '%s' "$p" | grep -qiE '(^|/)\.env($|\.)|(^|/)id_(rsa|dsa|ecdsa|ed25519)$|\.(pem|pfx|p12|keystore|jks)$|(^|/)\.aws/credentials$|(^|/)\.ssh/(id_|.*_key$)|(^|/)(credentials|secrets?)\.(json|ya?ml|toml)$|(^|/)service-account.*\.json$|(^|/)\.npmrc$|(^|/)\.pgpass$|(^|/)\.odoorc$|(^|/)odoo\.conf$'; then
  emit_deny "$leaf"
fi

# --- bulk noise: allowed, but flagged ---------------------------------------
if printf '%s' "$p" | grep -qiE '(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Cargo\.lock|composer\.lock|Gemfile\.lock)$|(^|/)(node_modules|dist|build|\.next|target|vendor|__pycache__)/|\.(min\.js|min\.css|map|bundle\.js|pyc)$|\.po$'; then
  emit_warn "$leaf"
fi

emit_allow
