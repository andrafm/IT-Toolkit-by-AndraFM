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

$keepApps = @('Microsoft.WindowsStore','Microsoft.StorePurchaseApp','Microsoft.DesktopAppInstaller','Microsoft.WindowsCalculator','Microsoft.Windows.Photos','Microsoft.WindowsNotepad','Microsoft.WindowsTerminal')
$removed = 0
Get-AppxPackage -AllUsers | Where-Object { $keepApps -notcontains $_.Name } | ForEach-Object {
    try {
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        Write-Output "Removed: $($_.Name)"
        $removed++
    } catch {
        Write-Output "Skipped: $($_.Name)"
    }
}
Write-Output "Store apps removal completed. Removed: $removed app(s).`nNote: Essential apps (Store, Calculator, Notepad, Photos, Terminal) were kept."
