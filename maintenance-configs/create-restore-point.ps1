param(
    [switch]$Execute
)

$config = [pscustomobject]@{
    Id            = "create-restore-point"
    Label         = "Create Restore Point"
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

# Enable System Protection on C: drive (required for Checkpoint-Computer to work)
$drive = "C:\\"
try {
    $enabled = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -Name 'RPSessionInterval' -ErrorAction SilentlyContinue) -ne $null
    Enable-ComputerRestore -Drive $drive -ErrorAction SilentlyContinue
    Write-Output "System Protection enabled on $drive"
}
catch {
    Write-Output "Note: Could not enable System Protection - $($_.Exception.Message)"
}

# Enable VSS (Volume Shadow Copy) service if disabled
$vss = Get-Service -Name 'VSS' -ErrorAction SilentlyContinue
if ($vss -and $vss.StartType -eq 'Disabled') {
    Set-Service -Name 'VSS' -StartupType Manual
    Write-Output "VSS service set to Manual"
}

$description = "ITToolkit Auto Maintenance - $(Get-Date -Format 'yyyyMMdd-HHmmss')"
try {
    Checkpoint-Computer -Description $description -RestorePointType 'MODIFY_SETTINGS'
    Write-Output "Restore point created: $description"
}
catch {
    Write-Output "Failed to create restore point: $($_.Exception.Message)"
}
