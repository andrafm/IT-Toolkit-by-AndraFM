Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoOwner = "andrafirmansyah250699-ship-it"
$repoName = "IT-Toolkit-by-AndraFM"
$releaseTag = "v2.1.9"

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

Write-Host "Removing security restrictions from extracted files..." -ForegroundColor Cyan
Get-ChildItem -Path $extractRoot -Recurse -Filter "*.ps1" | ForEach-Object {
    try {
        Unblock-File -Path $_.FullName -Confirm:$false -ErrorAction SilentlyContinue
    }
    catch {
        # Silently continue if unblock fails
    }
}

$toolkitPath = Get-ChildItem -Path $extractRoot -Recurse -Filter "ITToolkit.ps1" -File |
    Select-Object -First 1 -ExpandProperty FullName

if ([string]::IsNullOrWhiteSpace($toolkitPath) -or -not (Test-Path -Path $toolkitPath)) {
    throw "Cannot locate ITToolkit.ps1 after extracting package."
}

Write-Host "Launching toolkit..." -ForegroundColor Green
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
}
catch {
    Write-Host "Set-ExecutionPolicy (Process) is blocked. Trying child PowerShell fallback..." -ForegroundColor Yellow
}

try {
    & $toolkitPath
}
catch [System.Management.Automation.PSSecurityException] {
    Write-Host "Direct launch blocked by policy, retrying with powershell.exe -ExecutionPolicy Bypass..." -ForegroundColor Yellow
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $toolkitPath
    if ($LASTEXITCODE -ne 0) {
        throw "Toolkit failed to launch in fallback process. ExitCode=$LASTEXITCODE"
    }
}
