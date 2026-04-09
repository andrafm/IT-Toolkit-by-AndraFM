Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoOwner = "andrafirmansyah250699-ship-it"
$repoName = "IT-Toolkit-by-AndraFM"
$releaseTag = "v2.1.4"

$zipUrl = "https://github.com/$repoOwner/$repoName/archive/refs/tags/$releaseTag.zip"
$tempRoot = Join-Path $env:TEMP "ITToolkit-AndraFM"
$zipPath = Join-Path $tempRoot "$releaseTag.zip"
$extractRoot = Join-Path $tempRoot $releaseTag

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
catch {
    # Ignore if already on modern TLS.
}

if (-not (Test-Path -Path $tempRoot)) {
    New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null
}

if (Test-Path -Path $extractRoot) {
    Remove-Item -Path $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Downloading toolkit package from: $zipUrl" -ForegroundColor Cyan
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

Write-Host "Extracting package..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

$toolkitPath = Get-ChildItem -Path $extractRoot -Recurse -Filter "ITToolkit.ps1" -File |
    Select-Object -First 1 -ExpandProperty FullName

if ([string]::IsNullOrWhiteSpace($toolkitPath) -or -not (Test-Path -Path $toolkitPath)) {
    throw "Cannot locate ITToolkit.ps1 after extracting package."
}

Write-Host "Launching toolkit..." -ForegroundColor Green
& $toolkitPath
