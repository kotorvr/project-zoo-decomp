param([string]$Id, [string]$Title, [string]$Tree, [string]$Model, [string]$Brief, [string]$Settings,
      [string]$Mode = 'auto', [string]$LogDir, [string]$Branch, [switch]$Setup, [switch]$NoRemoteControl,
      [ValidateSet('A', 'C', 'D', 'E')][string]$Account = 'A', [string]$AcctDir)
# Project Zoo copy (2026-10-27) of KOTOR's copy of Echo's tools/w24/launch_manual_w23.ps1 (LAUNCH-1, 2026-10-25; accounts LAUNCH-2): runs inside the console
# launch.ps1 opens. Every CLAUDE* / ANTHROPIC_* / MCP_* variable is cleared; then a C / D / E chat gets
# CLAUDE_SECURESTORAGE_CONFIG_DIR = its account dir (Echo's form S: only the login comes from there; transcripts, memory,
# settings and the ListAgents registry stay in ~/.claude). A uses ~/.claude's own login.
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Start-Transcript -Path (Join-Path $LogDir "launch_$Id.log") -Force
Get-ChildItem Env: | Where-Object { $_.Name -match '^(CLAUDE|ANTHROPIC_|MCP_)' } | ForEach-Object { [Environment]::SetEnvironmentVariable($_.Name, $null, 'Process') }
if ($Account -ne 'A') {
    # refuse instead of falling back to account A: a chat keeps its account for life
    $home1 = (Join-Path $env:USERPROFILE '.claude').TrimEnd('\')
    if (-not $AcctDir -or $AcctDir.TrimEnd('\') -ieq $home1) { "REFUSED: account $Account dir '$AcctDir' is account A's"; Stop-Transcript; exit 3 }
    if (-not (Test-Path -LiteralPath (Join-Path $AcctDir '.credentials.json'))) { "REFUSED: no account-$Account login in $AcctDir"; Stop-Transcript; exit 3 }
    $env:CLAUDE_SECURESTORAGE_CONFIG_DIR = $AcctDir
}
# the user, 2026-10-26: the low-memory reaper killed 4 batches/walks in a day; chats run without it
$env:CLAUDE_CODE_DISABLE_BG_SHELL_PRESSURE_REAP = '1'
"account: $Account"
Set-Location -LiteralPath $Tree
$Host.UI.RawUI.WindowTitle = $Title
if ($Setup) {
    & python tools/worktree.py status | Select-Object -Last 1
    if ($LASTEXITCODE -ne 0) { & python -u tools/worktree.py setup --branch $Branch | Select-Object -Last 3 }
}
$text = Get-Content -Raw -Encoding UTF8 $Brief
# PS 5.1 native arg passing cuts the argument at an embedded double quote (Echo, DISK brief 10-24)
$text = $text.Replace('"', "'")
"tree: $Tree mode: $Mode brief chars: $($text.Length) start $(Get-Date -Format HH:mm:ss)"
$exe = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
$args1 = @('-n', $Title, '--model', $Model, '--permission-mode', $Mode, '--settings', $Settings)
if (-not $NoRemoteControl) { $args1 += @('--remote-control', $Title) }
& $exe @args1 $text
"claude exit rc=$LASTEXITCODE at $(Get-Date -Format HH:mm:ss)"
Stop-Transcript
