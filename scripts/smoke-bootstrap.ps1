param(
    [string]$RepoOwner = "andrafirmansyah250699-ship-it",
    [string]$RepoName = "IT-Toolkit-by-AndraFM"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "SMOKE FAILED: $Message"
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$bootstrapPath = Join-Path $repoRoot "bootstrap.ps1"

Assert-True (Test-Path -Path $bootstrapPath) "bootstrap.ps1 tidak ditemukan di root repo."

$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($bootstrapPath, [ref]$null, [ref]$parseErrors)
Assert-True (-not $parseErrors -or $parseErrors.Count -eq 0) "Syntax bootstrap.ps1 tidak valid."

$bootstrapContent = Get-Content -Path $bootstrapPath -Raw -Encoding UTF8
Assert-True ($bootstrapContent -notmatch 'Invoke-Expression\s+\$scriptContent') "Ditemukan baris lama Invoke-Expression `$scriptContent."
Assert-True ($bootstrapContent -match 'Expand-Archive\s+-Path\s+\$zipPath') "Launcher ZIP tidak ditemukan."
Assert-True ($bootstrapContent -match 'Get-ChildItem\s+-Path\s+\$extractRoot\s+-Recurse\s+-Filter\s+"ITToolkit\.ps1"') "Pencarian ITToolkit.ps1 tidak ditemukan."

$releaseTagMatch = [regex]::Match($bootstrapContent, '\$releaseTag\s*=\s*"([^"]+)"')
Assert-True $releaseTagMatch.Success "releaseTag tidak ditemukan di bootstrap.ps1."
$releaseTag = $releaseTagMatch.Groups[1].Value

$remoteUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$releaseTag/bootstrap.ps1"
Write-Host "Checking published bootstrap: $remoteUrl" -ForegroundColor Cyan

$remoteResponse = Invoke-WebRequest -Uri $remoteUrl -UseBasicParsing
$remoteContent = [string]$remoteResponse.Content

Assert-True ($remoteContent -match 'Expand-Archive\s+-Path\s+\$zipPath') "Published bootstrap belum mengandung launcher ZIP."
Assert-True ($remoteContent -notmatch 'Invoke-Expression\s+\$scriptContent') "Published bootstrap masih mengandung baris lama Invoke-Expression `$scriptContent."

Write-Host "SMOKE PASSED: bootstrap local + published release ($releaseTag) valid." -ForegroundColor Green