<#
  beforeShellExecution -- deterministic block of catastrophic commands.

  Costs zero tokens. This is the point: an instruction in a prompt is advice the
  model may ignore and that you pay for on every single turn. A hook is a rule
  the model cannot ignore and that you pay for never.

  Contract: read JSON on stdin, write JSON on stdout, exit 0.
  A malformed response is silently treated as "allow" by Cursor, so every path
  through this script must emit valid JSON. Hence the outer try/catch.
#>

$ErrorActionPreference = 'Stop'

function Write-Decision {
    param([string]$Permission, [string]$UserMessage = '', [string]$AgentMessage = '')
    $o = [ordered]@{ permission = $Permission }
    if ($UserMessage)  { $o.user_message  = $UserMessage }
    if ($AgentMessage) { $o.agent_message = $AgentMessage }
    ($o | ConvertTo-Json -Compress -Depth 5)
    exit 0
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { Write-Decision 'allow' }

    $cmd = ''
    try { $cmd = ($raw | ConvertFrom-Json).command } catch { Write-Decision 'allow' }
    if ([string]::IsNullOrWhiteSpace($cmd)) { Write-Decision 'allow' }

    $c = $cmd -replace '\s+', ' '

    # Patterns that are never a good idea unattended. Each entry: regex + reason.
    $deny = @(
        @{ Re = '(?i)\brm\s+(-[a-z]*\s+)*-[a-z]*[rR][a-z]*f|(?i)\brm\s+(-[a-z]*\s+)*-[a-z]*f[a-z]*[rR]'
           Why = 'recursive force delete' }
        @{ Re = '(?i)\b(mkfs|diskpart|format\s+[a-z]:)'
           Why = 'disk format' }
        @{ Re = '(?i)git\s+push\b.*?(--force(?!-with-lease)|(?<![\w-])-f(?![\w-]))'
           Why = 'force push without lease' }
        @{ Re = '(?i)git\s+(reset\s+--hard|clean\s+-[a-z]*f[a-z]*d|clean\s+-[a-z]*d[a-z]*f)'
           Why = 'discards uncommitted work' }
        @{ Re = '(?i)\bDROP\s+(DATABASE|SCHEMA|TABLE)\b'
           Why = 'destructive SQL' }
        @{ Re = '(?i)(curl|wget|iwr|irm)\b[^|;&]*\|\s*(sudo\s+)?(bash|sh|zsh|iex|powershell|pwsh)'
           Why = 'pipes remote content into a shell' }
        @{ Re = '(?i)\bchmod\s+(-R\s+)?777\b'
           Why = 'world-writable permissions' }
        @{ Re = ':\(\)\s*\{\s*:\|:&\s*\}\s*;:'
           Why = 'fork bomb' }
    )

    foreach ($d in $deny) {
        if ($c -match $d.Re) {
            Write-Decision 'deny' `
                "Blocked by guard-shell: $($d.Why)." `
                ("Blocked: $($d.Why). This guard is deterministic, not a judgment call -- " +
                 "do not rephrase the command to get around it. If this is genuinely " +
                 "required, stop and ask the user to run it themselves.")
        }
    }

    Write-Decision 'allow'
}
catch {
    # Never let a bug in this guard become a wall. Fail open, but say so.
    '{"permission":"allow","user_message":"guard-shell errored; command allowed"}'
    exit 0
}
