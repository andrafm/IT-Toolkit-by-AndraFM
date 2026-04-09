Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Pinned release URL for stable installs.
$toolkitUrl = "https://raw.githubusercontent.com/andrafirmansyah250699-ship-it/IT-Toolkit-by-AndraFM/v2.1.1/ITToolkit.ps1"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
catch {
    # Ignore if already on modern TLS.
}

Write-Host "Downloading toolkit from: $toolkitUrl" -ForegroundColor Cyan
$scriptContent = Invoke-RestMethod -Uri $toolkitUrl -UseBasicParsing

if ([string]::IsNullOrWhiteSpace($scriptContent)) {
    throw "Toolkit script is empty or failed to download."
}

Invoke-Expression $scriptContent
