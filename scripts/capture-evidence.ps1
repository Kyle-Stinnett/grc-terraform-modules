# scripts/capture-evidence.ps1
param(
    [Parameter(Mandatory=$true)][string]$Workspace,
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$Vault,
    [string]$Profile
)

$ErrorActionPreference = "Stop"

$WorkDir   = Join-Path $env:TEMP "evidence-$RunId"
$BundleDir = Join-Path $WorkDir "bundle-$RunId"
New-Item -ItemType Directory -Force -Path $BundleDir | Out-Null

$CapturedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# plan.json
if (Test-Path (Join-Path $Workspace "tfplan")) {
    try {
        Push-Location $Workspace
        terraform show -json tfplan 2>$null | Out-File "$BundleDir\plan.json" -Encoding utf8
    } catch {} finally { Pop-Location }
}

# state.json
try {
    Push-Location $Workspace
    terraform state pull 2>$null | Out-File "$BundleDir\state.json" -Encoding utf8
} catch {} finally { Pop-Location }

# commit.txt
try {
    $gitLog = git -C $Workspace log -1 --pretty=full 2>$null
    if ($gitLog) {
        $gitLog | Out-File "$BundleDir\commit.txt" -Encoding utf8
    } else {
        "no git commit available" | Out-File "$BundleDir\commit.txt" -Encoding utf8
    }
} catch {
    "no git commit available" | Out-File "$BundleDir\commit.txt" -Encoding utf8
}

# version.txt
terraform version | Out-File "$BundleDir\version.txt" -Encoding utf8

# manifest.json
$manifest = @()
Get-ChildItem -Path $BundleDir -File | Where-Object { $_.Name -ne "manifest.json" } | ForEach-Object {
    $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLower()
    $manifest += [ordered]@{
        filename        = $_.Name
        sha256          = $hash
        size            = $_.Length
        captured_at_utc = $CapturedAt
    }
}
$manifest | ConvertTo-Json | Out-File "$BundleDir\manifest.json" -Encoding utf8

# Bundle into tar.gz
$BundleTgz = Join-Path $env:TEMP "bundle-$RunId.tar.gz"
Push-Location $WorkDir
tar -czf $BundleTgz "bundle-$RunId"
Pop-Location

# Upload to S3
$Key     = "runs/$RunId/bundle.tar.gz"
$awsArgs = @("s3api", "put-object", "--bucket", $Vault, "--key", $Key, "--body", $BundleTgz, "--output", "json")
if ($Profile) { $awsArgs = @("--profile", $Profile) + $awsArgs }
$UploadOut = aws @awsArgs
$VersionId = ($UploadOut | ConvertFrom-Json).VersionId

# Print JSON receipt
[ordered]@{
    run_id          = $RunId
    vault           = $Vault
    key             = $Key
    version_id      = $VersionId
    captured_at_utc = $CapturedAt
} | ConvertTo-Json -Compress

# Cleanup
Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue
Remove-Item -Force $BundleTgz -ErrorAction SilentlyContinue