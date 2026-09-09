<#
  afterFileEdit -- run the project formatter on the file that just changed.

  This exists to delete a prompt instruction. "Always run the formatter after
  editing" is a sentence you pay for on every turn of every session, that the
  model sometimes forgets, and that produces a tool call and a response you also
  pay for. Doing it here costs nothing and never forgets.

  Deliberately conservative: only runs a formatter the project has already
  configured, never installs anything, and gives up fast.
#>

$ErrorActionPreference = 'Stop'

function Write-Ok {
    param([string]$AgentMessage = '')
    $o = [ordered]@{ continue = $true }
    if ($AgentMessage) { $o.agent_message = $AgentMessage }
    ($o | ConvertTo-Json -Compress -Depth 5)
    exit 0
}

function Find-Up {
    param([string]$StartDir, [string[]]$Names)
    $d = $StartDir
    for ($i = 0; $i -lt 8 -and $d; $i++) {
        foreach ($n in $Names) {
            if (Test-Path (Join-Path $d $n)) { return $d }
        }
        $parent = Split-Path -Parent $d
        if ($parent -eq $d) { break }
        $d = $parent
    }
    return $null
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { Write-Ok }

    $file = ''
    try { $file = ($raw | ConvertFrom-Json).file_path } catch { Write-Ok }
    if (-not $file -or -not (Test-Path $file)) { Write-Ok }

    $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
    $dir = Split-Path -Parent $file

    $cmd = $null; $cmdArgs = $null; $runIn = $dir

    switch -Regex ($ext) {
        '^\.(ts|tsx|js|jsx|mjs|cjs|json|css|scss|md|html|yaml|yml)$' {
            $root = Find-Up $dir @('.prettierrc', '.prettierrc.json', '.prettierrc.js',
                                   '.prettierrc.cjs', '.prettierrc.yaml', '.prettierrc.yml',
                                   'prettier.config.js', 'prettier.config.cjs')
            if ($root) { $cmd = 'npx'; $cmdArgs = @('--no-install', 'prettier', '--write', $file); $runIn = $root }
        }
        '^\.py$' {
            $root = Find-Up $dir @('pyproject.toml', 'ruff.toml', '.ruff.toml')
            if ($root -and (Get-Command ruff -ErrorAction SilentlyContinue)) {
                $cmd = 'ruff'; $cmdArgs = @('format', $file); $runIn = $root
            }
        }
        '^\.go$' {
            if (Get-Command gofmt -ErrorAction SilentlyContinue) { $cmd = 'gofmt'; $cmdArgs = @('-w', $file) }
        }
        '^\.rs$' {
            if (Get-Command rustfmt -ErrorAction SilentlyContinue) { $cmd = 'rustfmt'; $cmdArgs = @($file) }
        }
    }

    if (-not $cmd) { Write-Ok }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $cmd
    foreach ($a in $cmdArgs) { $null = $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $runIn
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    if (-not $proc.WaitForExit(15000)) {
        try { $proc.Kill() } catch {}
        Write-Ok
    }

    if ($proc.ExitCode -ne 0) {
        $err = ''
        try { $err = $proc.StandardError.ReadToEnd() } catch {}
        if ($err.Length -gt 400) { $err = $err.Substring(0, 400) + '...' }
        Write-Ok "Formatter ($cmd) failed on $(Split-Path -Leaf $file). This usually means a syntax error in the edit you just made:`n$err"
    }

    Write-Ok
}
catch {
    '{"continue":true}'
    exit 0
}
