#!/bin/sh
# afterFileEdit -- run the project formatter on the file that just changed.
#
# This exists to delete a prompt instruction. "Always run the formatter after
# editing" is a sentence paid for on every turn of every session, that the model
# sometimes forgets, and that produces a tool call and a response also paid for.
# Doing it here costs nothing and never forgets.
#
# Deliberately conservative: only runs a formatter the project already has
# configured, never installs anything, and gives up fast.

set -u

ok() { printf '{"continue":true}\n'; exit 0; }
ok_msg() { printf '{"continue":true,"agent_message":"%s"}\n' "$1"; exit 0; }

trap 'printf "{\"continue\":true}\n"; exit 0' HUP INT TERM

input=$(cat 2>/dev/null) || ok
[ -n "$input" ] || ok

file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\(\(\\.\|[^"\\]\)*\)".*/\1/p' 2>/dev/null)
[ -n "$file" ] || ok
[ -f "$file" ] || ok

dir=$(dirname "$file")
ext=$(printf '%s' "$file" | sed -n 's/.*\.\([a-zA-Z0-9]*\)$/\1/p' | tr 'A-Z' 'a-z')

# Walk up looking for a config file, at most 8 levels.
find_up() {
  d="$dir"; i=0
  while [ "$i" -lt 8 ] && [ -n "$d" ] && [ "$d" != "/" ]; do
    for n in $1; do
      if [ -e "$d/$n" ]; then printf '%s' "$d"; return 0; fi
    done
    parent=$(dirname "$d")
    [ "$parent" = "$d" ] && break
    d="$parent"; i=$((i + 1))
  done
  return 1
}

cmd=''; runin="$dir"

case "$ext" in
  ts|tsx|js|jsx|mjs|cjs|json|css|scss|md|html|yaml|yml)
    if root=$(find_up ".prettierrc .prettierrc.json .prettierrc.js .prettierrc.cjs .prettierrc.yaml .prettierrc.yml prettier.config.js prettier.config.cjs"); then
      command -v npx >/dev/null 2>&1 && { cmd="npx --no-install prettier --write"; runin="$root"; }
    fi
    ;;
  py)
    # Odoo and most Python projects: ruff if configured, else black.
    if root=$(find_up "pyproject.toml ruff.toml .ruff.toml"); then
      if command -v ruff >/dev/null 2>&1; then cmd="ruff format"; runin="$root"
      elif command -v black >/dev/null 2>&1; then cmd="black -q"; runin="$root"
      fi
    fi
    ;;
  go)  command -v gofmt   >/dev/null 2>&1 && cmd="gofmt -w" ;;
  rs)  command -v rustfmt >/dev/null 2>&1 && cmd="rustfmt" ;;
esac

[ -n "$cmd" ] || ok

err=$(cd "$runin" 2>/dev/null && $cmd "$file" 2>&1 >/dev/null)
status=$?

if [ "$status" -ne 0 ]; then
  # Keep it short and JSON-safe.
  msg=$(printf '%s' "$err" | head -c 300 | tr '\n"\\' '   ')
  ok_msg "Formatter failed on $(basename "$file"). This usually means a syntax error in the edit just made: $msg"
fi

ok
