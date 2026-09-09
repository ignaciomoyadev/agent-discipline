#!/bin/sh
# beforeShellExecution -- deterministic block of catastrophic commands.
#
# POSIX sh, no external dependencies. jq is deliberately not used: it is not
# installed by default on most server images, and a guard that fails because a
# tool is missing is worse than no guard -- with failClosed it blocks everything.
#
# Contract: read JSON on stdin, write JSON on stdout, exit 0.
# Cursor treats a malformed response as "allow", silently, so every path here
# must print valid JSON. Hence the trap and the fallback at the end.

set -u

emit() {
  # $1 = permission, $2 = user_message (optional), $3 = agent_message (optional)
  if [ -n "${2:-}" ] && [ -n "${3:-}" ]; then
    printf '{"permission":"%s","user_message":"%s","agent_message":"%s"}\n' "$1" "$2" "$3"
  else
    printf '{"permission":"%s"}\n' "$1"
  fi
  exit 0
}

trap 'printf "{\"permission\":\"allow\",\"user_message\":\"guard-shell errored; command allowed\"}\n"; exit 0' HUP INT TERM

input=$(cat 2>/dev/null) || emit allow
[ -n "$input" ] || emit allow

# Pull the "command" string out of the payload. Handles escaped quotes.
cmd=$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(\(\\.\|[^"\\]\)*\)".*/\1/p' 2>/dev/null)
[ -n "$cmd" ] || emit allow

# Unescape the sequences that matter for pattern matching.
c=$(printf '%s' "$cmd" | sed 's/\\"/"/g; s/\\\\/\\/g' | tr '\n' ' ')

deny() {
  emit deny \
    "Blocked by guard-shell: $1." \
    "Blocked: $1. This guard is deterministic, not a judgment call -- do not rephrase the command to get around it. If this is genuinely required, stop and ask the user to run it themselves."
}

# --- recursive force delete -------------------------------------------------
if printf '%s' "$c" | grep -qE '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*-[a-zA-Z]*([rR][a-zA-Z]*f|f[a-zA-Z]*[rR])'; then
  deny "recursive force delete"
fi

# --- disk destruction -------------------------------------------------------
if printf '%s' "$c" | grep -qiE '(^|[;&|[:space:]])(mkfs|diskpart|dd[[:space:]]+if=.*of=/dev/)'; then
  deny "disk destruction"
fi

# --- force push without lease -----------------------------------------------
if printf '%s' "$c" | grep -qE 'git[[:space:]]+push'; then
  if printf '%s' "$c" | grep -qE '\-\-force-with-lease'; then
    :
  elif printf '%s' "$c" | grep -qE '(\-\-force([^-]|$)|[[:space:]]-f([[:space:]]|$))'; then
    deny "force push without lease"
  fi
fi

# --- discards uncommitted work ----------------------------------------------
if printf '%s' "$c" | grep -qE 'git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[a-zA-Z]*([fF][a-zA-Z]*d|d[a-zA-Z]*[fF]))'; then
  deny "discards uncommitted work"
fi

# --- destructive SQL --------------------------------------------------------
if printf '%s' "$c" | grep -qiE 'DROP[[:space:]]+(DATABASE|SCHEMA|TABLE)|TRUNCATE[[:space:]]+TABLE'; then
  deny "destructive SQL"
fi

# --- remote content piped into a shell --------------------------------------
if printf '%s' "$c" | grep -qiE '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh'; then
  deny "pipes remote content into a shell"
fi

# --- world-writable ---------------------------------------------------------
if printf '%s' "$c" | grep -qE 'chmod[[:space:]]+(-R[[:space:]]+)?777'; then
  deny "world-writable permissions"
fi

# --- fork bomb --------------------------------------------------------------
if printf '%s' "$c" | grep -qE ':\(\)[[:space:]]*\{[[:space:]]*:\|:&[[:space:]]*\}[[:space:]]*;:'; then
  deny "fork bomb"
fi

emit allow
