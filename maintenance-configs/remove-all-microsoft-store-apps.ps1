param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-all-microsoft-store-apps'
    Label         = 'Remove all Microsoft Store apps'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$targetApps = @(
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.BingNews',
    'Microsoft.BingSearch',
    'Microsoft.BingWeather',
    'Clipchamp.Clipchamp',
    'Microsoft.Todos',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.WindowsSoundRecorder',
    'Microsoft.MicrosoftStickyNotes',
    'Microsoft.Windows.DevHome',
    'Microsoft.Paint',
    'Microsoft.OutlookForWindows',
    'Microsoft.WindowsAlarms',
    'Microsoft.StartExperiencesApp',
    'Microsoft.GetHelp',
    'Microsoft.ZuneMusic',
    'MicrosoftCorporationII.QuickAssist',
    'MSTeams'
)

$removed = 0
foreach ($appName in $targetApps) {
    $pkg = Get-AppxPackage -AllUsers -Name $appName -ErrorAction SilentlyContinue
    if ($pkg) {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
            Write-Output "Removed: $appName"
            $removed++
        } catch {
            Write-Output "Skipped: $appName"
        }
    } else {
        Write-Output "Not found: $appName"
    }
}

# Uninstall legacy Teams if present
$teamsPath = "$Env:LocalAppData\Microsoft\Teams\Update.exe"
if (Test-Path $teamsPath) {
    Write-Output "Uninstalling legacy Teams..."
    Start-Process $teamsPath -ArgumentList '-uninstall' -Wait -ErrorAction SilentlyContinue
    Remove-Item (Split-Path $teamsPath) -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "Legacy Teams removed."
}

Write-Output "`nDebloat completed. Removed: $removed app(s)."
