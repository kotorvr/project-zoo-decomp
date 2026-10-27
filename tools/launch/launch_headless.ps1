param([string]$Id, [string]$Title, [string]$Tree, [string]$Model, [string]$Brief, [string]$Settings,
      [string]$Mode = 'auto', [string]$LogDir, [string]$Branch, [switch]$Setup,
      [ValidateSet('API1', 'API2', 'API3')][string]$Account, [string]$AcctDir, [string]$Sid = '')
# Project Zoo copy (2026-10-27) of KOTOR's copy of Echo's tools/w24/launch_headless_w24.ps1 (LAUNCH-2, 2026-10-25): API-key accounts only. The promo API
# credits cover print mode but refuse the interactive CLI, so the chat runs as `claude -p` (brief on stdin) and is resumed
# with --resume until <LogDir>\stop_<Id> exists. The key is read by apiKeyHelper from <AcctDir>\key.txt (launch.ps1 writes
# it into the --settings file); it is never printed. -Sid: move an existing headless session to this key.
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$out = Join-Path $LogDir "hl_$Id.jsonl"
Start-Transcript -Path (Join-Path $LogDir "launch_$Id.log") -Force
Get-ChildItem Env: | Where-Object { $_.Name -match '^(CLAUDE|ANTHROPIC_|MCP_)' } | ForEach-Object { [Environment]::SetEnvironmentVariable($_.Name, $null, 'Process') }
if (-not (Test-Path -LiteralPath (Join-Path $AcctDir 'key.txt'))) { "REFUSED: no key.txt in $AcctDir"; Stop-Transcript; exit 3 }
$env:CLAUDE_SECURESTORAGE_CONFIG_DIR = $AcctDir
Set-Location -LiteralPath $Tree
$Host.UI.RawUI.WindowTitle = "$Title (headless $Account)"
if ($Setup) {
    & python tools/worktree.py status | Select-Object -Last 1
    if ($LASTEXITCODE -ne 0) { & python -u tools/worktree.py setup --branch $Branch | Select-Object -Last 3 }
}
$exe = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
$note = "HEADLESS CHAT (tools/launch): you run as claude -p on an API key. NEVER end your turn while you have work or may get messages: when idle, run Bash 'sleep 240' calls one after another (each tool round delivers your cross-session messages). End the turn only at your handoff, after your handoff commit + message to the orchestrator.`n"
$text = $note + (Get-Content -Raw -Encoding UTF8 $Brief)
"account: $Account headless; tree: $Tree brief chars: $($text.Length) start $(Get-Date -Format HH:mm:ss)"
$base = @('-n', $Title, '--model', $Model, '--permission-mode', $Mode, '--settings', $Settings, '--output-format', 'stream-json', '--verbose')
if ($Sid) {
    "moved session $Sid to $Account"
} else {
    $text | & $exe -p @base | Out-File -Append -Encoding utf8 $out
    "claude exit rc=$LASTEXITCODE at $(Get-Date -Format HH:mm:ss)"
    $Sid = (Select-String -Path $out -Pattern '"session_id":"([0-9a-f-]{36})"' | Select-Object -First 1).Matches[0].Groups[1].Value
}
for ($i = 1; $i -le 40 -and -not (Test-Path (Join-Path $LogDir "stop_$Id")); $i++) {
    if ($i -gt 1 -or -not $Sid) { Start-Sleep 60 }
    "resume $i sid $Sid at $(Get-Date -Format HH:mm:ss)"
    'RESUMED (headless loop): your process exited. Check git log and your messages, then carry on with your brief; idle = Bash sleep 240 loop; end the turn only at handoff.' | & $exe -p --resume $Sid @base | Out-File -Append -Encoding utf8 $out
    "claude exit rc=$LASTEXITCODE at $(Get-Date -Format HH:mm:ss)"
}
Stop-Transcript
