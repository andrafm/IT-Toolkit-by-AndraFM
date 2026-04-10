Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$today = (Get-Date).ToString("yyyyMMdd")
$bootstrapUrl = "https://raw.githubusercontent.com/andrafirmansyah250699-ship-it/IT-Toolkit-by-AndraFM/master/bootstrap.ps1?bust=$today"

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