param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-outlook'
    Label         = 'Remove Microsoft Outlook (new)'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

# Remove new Outlook (Store app)
$pkg = Get-AppxPackage -AllUsers -Name 'Microsoft.OutlookForWindows' -ErrorAction SilentlyContinue
if ($pkg) {
    try {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        Write-Output "Removed: Microsoft Outlook (new Store app)"
    } catch {
        Write-Output "Failed to remove Outlook Store app: $_"
    }
} else {
    Write-Output "Outlook (new Store app) not found or already removed."
}

# Block Outlook from being reinstalled via provisioned package
$provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'Microsoft.OutlookForWindows' }
if ($provisioned) {
    Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction SilentlyContinue
    Write-Output "Removed provisioned Outlook package (prevents reinstall for new users)."
}

Write-Output "`nOutlook removal completed."
