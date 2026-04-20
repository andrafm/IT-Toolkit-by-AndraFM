Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =========================
# UI HELPER (CENTER TEXT)
# =========================
function Write-Center {
    param (
        [string]$text,
        [string]$color = "White"
    )
    $width = $Host.UI.RawUI.WindowSize.Width
    $padding = [math]::Max(0, ($width - $text.Length) / 2)
    Write-Host (" " * [int]$padding + $text) -ForegroundColor $color
}

# =========================
# SPLASH SCREEN (NEON STYLE)
# =========================
Clear-Host

$logo = @(
"████████╗ ██████╗  ██████╗ ██╗     ██╗  ██╗██╗████████╗",
"╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██║ ██╔╝██║╚══██╔══╝",
"   ██║   ██║   ██║██║   ██║██║     █████╔╝ ██║   ██║   ",
"   ██║   ██║   ██║██║   ██║██║     ██╔═██╗ ██║   ██║   ",
"   ██║   ╚██████╔╝╚██████╔╝███████╗██║  ██╗██║   ██║   ",
"   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝   "
)

Write-Host ""

# Flicker effect (matrix style)
foreach ($line in $logo) {
    Write-Center $line "DarkGreen"
    Start-Sleep -Milliseconds 20
}
foreach ($line in $logo) {
    Write-Center $line "Green"
    Start-Sleep -Milliseconds 20
}
foreach ($line in $logo) {
    Write-Center $line "Cyan"
}

Write-Host ""
Write-Center "by AndraFM_" "DarkGray"
Write-Host ""
Write-Center "Automation • Tools • Utilities" "Gray"

Write-Host ""
Write-Center ("═" * 40) "DarkGray"
Write-Host ""

# =========================
# PROGRESS BAR (SINGLE LINE)
# =========================
function Show-Progress {
    param (
        [string]$status,
        [int]$delay = 60
    )

    for ($i = 0; $i -le 100; $i += 5) {
        $barCount = [math]::Floor($i / 5)
        $bar = ("█" * $barCount).PadRight(20, "-")
        $text = "[{0}] {1}%  {2}" -f $bar, $i, $status

        $width = $Host.UI.RawUI.WindowSize.Width
        $padding = [math]::Max(0, ($width - $text.Length) / 2)

        Write-Host (" " * [int]$padding + $text) -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds $delay
        Write-Host "`r" -NoNewline
    }
}

# =========================
# CONFIG
# =========================
$repoOwner = "andrafm"
$repoName  = "IT-Toolkit-by-AndraFM"
$cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$bootstrapUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/master/bootstrap.ps1?bust=$cacheBust"

# =========================
# STEP 1: GET LATEST SHA
# =========================
Show-Progress "Checking latest version..."

try {
    $branchInfoUrl = "https://api.github.com/repos/$repoOwner/$repoName/branches/master"
    $branchInfo = Invoke-RestMethod -Uri $branchInfoUrl -UseBasicParsing -Headers @{ "User-Agent" = "ITToolkit-Launcher" }
    $headSha = [string]$branchInfo.commit.sha

    if (-not [string]::IsNullOrWhiteSpace($headSha)) {
        $bootstrapUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$headSha/bootstrap.ps1"
    }
}
catch {
    # fallback
}

# =========================
# STEP 2: TLS SETUP
# =========================
Show-Progress "Preparing secure connection..."

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
catch {}

# =========================
# STEP 3: DOWNLOAD BOOTSTRAP
# =========================
Show-Progress "Downloading core files..."

$response = Invoke-WebRequest -Uri $bootstrapUrl -UseBasicParsing
$content = [string]$response.Content

# Remove BOM if exists
if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) {
    $content = $content.Substring(1)
}

# =========================
# FINAL STATUS
# =========================
$final = "[████████████████████] 100%  Ready!"
$padding = [math]::Max(0, ($Host.UI.RawUI.WindowSize.Width - $final.Length) / 2)
Write-Host (" " * [int]$padding + $final) -ForegroundColor Cyan

Write-Host ""

# =========================
# EXECUTE
# =========================
Invoke-Expression $content
