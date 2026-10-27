param([Parameter(Mandatory = $true)][string]$Spec,
      [ValidateSet('auto', 'acceptEdits', 'manual', 'dontAsk', 'plan', 'bypassPermissions')][string]$Mode = 'bypassPermissions',
      [int]$Gap = 5,
      [string]$TreeRoot = 'D:\ZooTrees',
      [switch]$NoRemoteControl,
      [ValidateSet('auto', 'A', 'C', 'D', 'E', 'API1', 'API2', 'API3')][string]$Account = 'D',
      [int]$CheckWait = 180)
# Project Zoo copy (2026-10-27) of KOTOR's copy of Echo's tools/w24/batch_launch_w23.ps1 (LAUNCH-1, 2026-10-25; Echo's accounts A C D E API1-3, LAUNCH-2).
# Spec lines: Id|Title|Model|BriefPath[|main][|<account>]. One console per line, running launch_one.ps1 (API1-3:
# launch_headless.ps1). Account: the spec field, else -Account (default D, the user 2026-10-25: "chats should be running on D"),
# or 'auto' = accounts.py pick (weekly usage from both
# Zoo's, KOTOR's and Echo's status-line dumps). After the start, accounts.py check proves the chat runs on that account; a FAILED
# check stops the chat by its PID (it would be running on A). A field "main" runs the chat
# in the main tree (orchestrator, planner); otherwise it gets the worktree <TreeRoot>\<id> on branch <id> (reused if it
# exists, so a successor at a handoff keeps its predecessor's tree), readied by tools/worktree.py setup in the console.
# -Mode defaults to bypassPermissions, like Echo (the user, 2026-10-25: "yes please"); -Mode auto for a classifier-checked chat.
# Each launch appends a LAUNCHED line with the claude.exe PID to <main>\Intermediate\launch\launched_sessions.log.
$ErrorActionPreference = 'Stop'
$main = Split-Path -Parent ((& git -C $PSScriptRoot rev-parse --path-format=absolute --git-common-dir).Trim())
$main = $main -replace '/', '\'
$launchDir = Join-Path $main 'Intermediate\launch'
$logDir = Join-Path $launchDir 'logs'
$logFile = Join-Path $launchDir 'launched_sessions.log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$accPy = Join-Path $PSScriptRoot 'accounts.py'
$accts = @('A', 'C', 'D', 'E', 'API1', 'API2', 'API3')
$py = (Get-Command python).Source -replace '\\', '/'
$slPy = (Join-Path $PSScriptRoot 'statusline_dump.py') -replace '\\', '/'
foreach ($line in (Get-Content $Spec)) {
    if (-not $line.Trim() -or $line.TrimStart().StartsWith('#')) { continue }
    $id, $title, $model, $brief, $rest = $line.Split('|') | ForEach-Object { $_.Trim() }
    if (-not ($id -and $title -and $model -and $brief)) { "REFUSED: bad spec line '$line'"; continue }
    if (-not (Test-Path -LiteralPath $brief)) { "$id REFUSED: no brief $brief"; continue }
    $where = if ($rest -contains 'main') { 'main' } else { '' }
    $acct = $rest | Where-Object { $_ -in $accts } | Select-Object -First 1
    if (-not $acct) { $acct = $Account }
    if ($acct -eq 'auto') {
        $pk = (& python $accPy pick | Select-String '^PICK ' | Select-Object -Last 1).Line
        $acct = if ($pk) { $pk.Substring(5).Trim() } else { 'NONE' }
        if ($acct -notin $accts) { "$id REFUSED: accounts.py pick says '$pk'"; continue }
    }
    $api = $acct -like 'API*'
    $aDir = if ($acct -eq 'A') { Join-Path $env:USERPROFILE '.claude' } else { Join-Path $env:USERPROFILE ".claude-$($acct.ToLower())" }
    $need = if ($api) { 'key.txt' } else { '.credentials.json' }
    if ($acct -ne 'A' -and -not (Test-Path -LiteralPath (Join-Path $aDir $need))) { "$id REFUSED: no account-$acct login in $aDir"; continue }
    $branch = $id.ToLower()
    if ($where -eq 'main') {
        $tree = $main
    } else {
        $tree = Join-Path $TreeRoot $branch
        if (-not (Test-Path -LiteralPath $tree)) {
            & git -C $main show-ref --verify --quiet "refs/heads/$branch"
            # git prints 'Preparing worktree' on stderr: under 'Stop' PS 5.1 turns that into a terminating error (DLG-1 launch, 2026-10-25)
            $ErrorActionPreference = 'Continue'
            if ($LASTEXITCODE -eq 0) { & git -C $main worktree add $tree $branch 2>&1 | Out-Null }
            else { & git -C $main worktree add $tree -b $branch main 2>&1 | Out-Null }
            $ErrorActionPreference = 'Stop'
            if (-not (Test-Path -LiteralPath $tree)) { "$id REFUSED: git worktree add $tree failed"; continue }
        }
    }
    # per-chat statusline (Echo's statusline_dump.py): 5-hour %, weekly %, context % -> <main>\Intermediate\launch\sl_<acct>\<session>.json
    # one dir per account, like Echo's sl_<x>: two accounts' percentages never share a dir
    $slDir = Join-Path $launchDir "sl_$($acct.ToLower())"
    New-Item -ItemType Directory -Force -Path $slDir | Out-Null
    $st = Join-Path $slDir "settings_$branch.json"
    $sl = @{ statusLine = @{ type = 'command'; command = "$py $slPy $($slDir -replace '\\', '/')" } }
    if ($api) { $sl.apiKeyHelper = "cmd /c type $aDir\key.txt" }
    Set-Content -Encoding ASCII -Path $st -Value ($sl | ConvertTo-Json -Compress -Depth 5)
    $rc = if ($NoRemoteControl) { ' -NoRemoteControl' } else { '' }
    $wt = if ($where -eq 'main') { '' } else { " -Setup -Branch $branch" }
    if ($api) { $one = Join-Path $PSScriptRoot 'launch_headless.ps1'; $rc = '' } else { $one = Join-Path $PSScriptRoot 'launch_one.ps1' }
    $cmd = "conhost.exe powershell.exe -NoExit -ExecutionPolicy Bypass -File `"$one`" -Id $branch -Title `"$title`" -Tree `"$tree`" -Model $model -Brief `"$brief`" -Settings `"$st`" -Mode $Mode -LogDir `"$logDir`" -Account $acct -AcctDir `"$aDir`"$wt$rc"
    $r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = $cmd; CurrentDirectory = $tree}
    $con = $r.ProcessId
    # worktree setup runs first in the console (1-2 min on a fresh tree), so wait up to 5 min for claude.exe
    $cl = $null
    for ($k = 0; $k -lt 150 -and -not $cl; $k++) {
        Start-Sleep 2
        $all = Get-CimInstance Win32_Process
        $ps = $all | Where-Object { $_.ParentProcessId -eq $con -and $_.Name -eq 'powershell.exe' }
        foreach ($p in $ps) { $cl = $all | Where-Object { $_.ParentProcessId -eq $p.ProcessId -and $_.Name -eq 'claude.exe' } | Select-Object -First 1 }
        if (-not $ps -and $k -gt 5) { break }
    }
    $cpid = if ($cl) { $cl.ProcessId } else { 'UNKNOWN' }
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Encoding ASCII -Path $logFile -Value "[$ts] LAUNCHED $id title='$title' pid=$cpid console=$con tree=$tree model=$model acct=$acct mode=$Mode brief=$brief"
    "$id pid=$cpid console=$con tree=$tree mode=$Mode acct=$acct"
    Start-Sleep $Gap
    if ($cl -and -not (Get-Process -Id $cpid -ErrorAction SilentlyContinue)) { "$id EXITED after start (read $logDir\launch_$branch.log)"; continue }
    if (-not $cl) { continue }
    if ($api) { "$id ACCOUNT CHECK NOT RUN: $acct is an API key (headless, no rate limits in the status line); read $logDir\hl_$branch.jsonl"; continue }
    # the account check (Echo's risk note: a claude.exe that drops CLAUDE_SECURESTORAGE_CONFIG_DIR silently runs on A)
    $v = & python $accPy check $acct $cpid --wait $CheckWait | Select-Object -Last 1
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Encoding ASCII -Path $logFile -Value "[$ts] $id pid=$cpid $v"
    if ($v -like 'ACCOUNT CHECK OK*') { "$id $v" }
    else {
        Stop-Process -Id $cpid -ErrorAction SilentlyContinue
        Write-Host "!!!!! $id $v - STOPPED pid $cpid (console $con left open for its log); launch nothing more on $acct until this is understood" -ForegroundColor Red
    }
}
