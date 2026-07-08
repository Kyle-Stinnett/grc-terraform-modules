# scripts/policy-gate.ps1
# PowerShell port of policy-gate.sh for machines without bash/WSL/Git Bash.
# Usage: .\policy-gate.ps1 -Workspace ..\lab-2-3 [-PolicyDir policies]

param(
    [Parameter(Mandatory = $true)]
    [string]$Workspace,

    [string]$PolicyDir = "policies"
)

$ErrorActionPreference = "Stop"

# Anchor evidence output to the repo root (three levels up from this script:
# scripts -> lab-3-4 -> Labs -> repo root), so it lands in the same place
# regardless of which directory you ran this script from.
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$EvidenceDir = Join-Path $RepoRoot "evidence\lab-3-4"
New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null

$WorkspaceFull = (Resolve-Path $Workspace).Path
$PlanJson = Join-Path $WorkspaceFull "plan.json"

Push-Location $WorkspaceFull
try {
    terraform show -json tfplan | Out-File -FilePath $PlanJson -Encoding utf8
} finally {
    Pop-Location
}

$namespaces = @(
    "compliance.sc28_aws",
    "compliance.ac3_aws",
    "compliance.cm6_aws",
    "compliance.cm6"
)

$allResults = @()
$overallExit = 0

foreach ($ns in $namespaces) {
    $raw = & conftest test --policy $PolicyDir --namespace $ns --output=json $PlanJson 2>$null
    if (-not $raw) { $raw = "[]" }

    try {
        $parsed = $raw | ConvertFrom-Json
    } catch {
        Write-Warning "Could not parse conftest output for namespace $ns"
        $parsed = @()
        $overallExit = 1
    }

    $hasFailures = $false
    foreach ($result in $parsed) {
        if ($result.failures -and $result.failures.Count -gt 0) {
            $hasFailures = $true
        }
    }
    if ($hasFailures) { $overallExit = 1 }

    $allResults += $parsed
}

$resultsPath = Join-Path $EvidenceDir "conftest-results.json"
$allResults | ConvertTo-Json -Depth 20 | Out-File -FilePath $resultsPath -Encoding utf8

if ($overallExit -eq 0) {
    Write-Host "policy-gate: PASS"
} else {
    Write-Host "policy-gate: FAIL"
    Write-Host "See $resultsPath"
}

exit $overallExit
