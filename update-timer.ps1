param(
    [string]$Note = 'Timer reset from PC',
    [switch]$SkipPublish
)

$ErrorActionPreference = 'Stop'

$repoDir = $PSScriptRoot
$timerStatePath = Join-Path $repoDir 'timer-state.json'
$timestamp = [DateTimeOffset]::UtcNow
$timestampMs = $timestamp.ToUnixTimeMilliseconds()
$timestampIso = $timestamp.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

$timerState = [ordered]@{
    schemaVersion = 1
    startedAt = $timestampMs
    startedAtIso = $timestampIso
    updatedAt = $timestampMs
    updatedAtIso = $timestampIso
    updatedBy = $env:USERNAME
    note = $Note
}

$timerState | ConvertTo-Json | Set-Content -Path $timerStatePath -Encoding UTF8
Write-Host "Timer state updated:" $timestampIso

if ($SkipPublish) {
    Write-Host 'Publish skipped.'
    exit 0
}

if (-not (Test-Path (Join-Path $repoDir '.git'))) {
    throw 'Git repository not found in site folder.'
}

git -C $repoDir add timer-state.json
$pendingChanges = git -C $repoDir diff --cached --name-only
if (-not $pendingChanges) {
    Write-Host 'No timer changes to publish.'
    exit 0
}

$commitMessage = @"
Update shared timer

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
"@

git -C $repoDir commit -m $commitMessage | Out-Null
git -C $repoDir push | Out-Null

Write-Host 'Timer published to GitHub Pages.'
