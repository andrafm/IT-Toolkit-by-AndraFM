Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoOwner = "andrafirmansyah250699-ship-it"
$repoName = "IT-Toolkit-by-AndraFM"
$cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$bootstrapUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/master/bootstrap.ps1?bust=$cacheBust"

try {
    $branchInfoUrl = "https://api.github.com/repos/$repoOwner/$repoName/branches/master"
    $branchInfo = Invoke-RestMethod -Uri $branchInfoUrl -UseBasicParsing -Headers @{ "User-Agent" = "ITToolkit-Launcher" }
    $headSha = [string]$branchInfo.commit.sha
    if (-not [string]::IsNullOrWhiteSpace($headSha)) {
        $bootstrapUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$headSha/bootstrap.ps1"
    }
}
catch {
    # Fallback to cache-busted master bootstrap URL.
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
catch {
    # Ignore if already on modern TLS.
}

Write-Host "Downloading bootstrap from: $bootstrapUrl" -ForegroundColor Cyan
$response = Invoke-WebRequest -Uri $bootstrapUrl -UseBasicParsing
$content = [string]$response.Content

if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) {
    $content = $content.Substring(1)
}

Invoke-Expression $content