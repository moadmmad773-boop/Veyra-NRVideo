# Writes REPORT.md (step results, error lines, log tails) and pushes it with the
# logs to the ci/results branch, so the build can be followed without Actions access.
$ErrorActionPreference = 'Continue'
$logs = $env:LOGS
$report = New-Item -ItemType Directory -Force (Join-Path $env:RUNNER_TEMP 'report')
$lines = @("# Test build $($env:GITHUB_RUN_ID) attempt $($env:GITHUB_RUN_ATTEMPT)", '',
    "- source: $($env:SOURCE_REF) @ $($env:SOURCE_SHA)", "- run: $($env:GITHUB_SERVER_URL)/$($env:GITHUB_REPOSITORY)/actions/runs/$($env:GITHUB_RUN_ID)",
    "- steps: deps=$($env:R_DEPS) build=$($env:R_BUILD) package=$($env:R_PACKAGE) publish=$($env:R_PUBLISH)", '')
foreach ($log in Get-ChildItem $logs -Filter *.log -ErrorAction SilentlyContinue | Sort-Object Name) {
    $text = Get-Content $log.FullName -ErrorAction SilentlyContinue
    $errors = $text | Select-String -Pattern 'error C\d+|error LNK\d+|fatal error|CMake Error|FAILED:|Exception|error:|WARNING:' | Select-Object -First 80
    $lines += "## $($log.Name)", '', '### errors', '```'
    $lines += ($errors | ForEach-Object { $_.Line })
    $lines += '```', '', '### tail', '```'
    $lines += ($text | Select-Object -Last 120)
    $lines += '```', ''
    Copy-Item $log.FullName $report
}
Set-Content (Join-Path $report 'REPORT.md') $lines -Encoding utf8
Push-Location $report
git init -q
git config user.name 'github-actions'
git config user.email 'github-actions@users.noreply.github.com'
git checkout -q -b ci/results
git add -A
git commit -q -m "Test build report $($env:GITHUB_RUN_ID)"
git push -q --force "https://x-access-token:$($env:GH_TOKEN)@github.com/$($env:GITHUB_REPOSITORY).git" ci/results
Pop-Location
Write-Host 'report pushed to ci/results'
