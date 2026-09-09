<#
  beforeReadFile -- keep secrets out of the context window.

  Two wins from one hook. The obvious one is that credentials never reach a
  model provider. The quieter one is token economics: a read .env or lockfile
  sits in context for the rest of the session, re-sent on every turn, priced on
  every turn, and useful on approximately none of them.

  Contract: read JSON on stdin, write JSON on stdout, exit 0.
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

    $path = ''
    try { $path = ($raw | ConvertFrom-Json).file_path } catch { Write-Decision 'allow' }
    if ([string]::IsNullOrWhiteSpace($path)) { Write-Decision 'allow' }

    $p    = $path -replace '\\', '/'
    $leaf = ($p -split '/')[-1]

    # Secrets: hard deny.
    $secret = @(
        '(?i)(^|/)\.env(\.|$)'
        '(?i)(^|/)\.env\.(local|production|prod|staging|development)$'
        '(?i)(^|/)id_(rsa|dsa|ecdsa|ed25519)$'
        '(?i)\.(pem|pfx|p12|keystore|jks)$'
        '(?i)(^|/)\.aws/credentials$'
        '(?i)(^|/)\.ssh/(id_|.*_key$)'
        '(?i)(^|/)(credentials|secrets?)\.(json|ya?ml|toml)$'
        '(?i)(^|/)service-account.*\.json$'
        '(?i)(^|/)\.npmrc$'
        '(?i)(^|/)\.pgpass$'
    )
    foreach ($re in $secret) {
        if ($p -match $re) {
            Write-Decision 'deny' `
                "guard-read blocked a credential file: $leaf" `
                ("Reading '$leaf' is blocked -- it holds credentials. Do not attempt a " +
                 "workaround such as cat, grep, or a shell redirect. If you need a value " +
                 "from it, ask the user for the specific key by name.")
        }
    }

    # Bulk noise: allowed, but flagged. These are enormous, rarely informative,
    # and once read they are billed on every subsequent turn.
    $bulk = @(
        '(?i)(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Cargo\.lock|composer\.lock|Gemfile\.lock)$'
        '(?i)(^|/)(node_modules|dist|build|\.next|target|vendor)/'
        '(?i)\.(min\.js|min\.css|map|bundle\.js)$'
    )
    foreach ($re in $bulk) {
        if ($p -match $re) {
            Write-Decision 'allow' '' `
                ("'$leaf' is a generated or vendored file. It is large and will stay in " +
                 "context for the rest of this session. Read it only if the task genuinely " +
                 "depends on its contents; prefer grep for a single fact.")
        }
    }

    Write-Decision 'allow'
}
catch {
    '{"permission":"allow","user_message":"guard-read errored; read allowed"}'
    exit 0
}
