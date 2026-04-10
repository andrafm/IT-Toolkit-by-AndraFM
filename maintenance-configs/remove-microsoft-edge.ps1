param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-microsoft-edge'
    Label         = 'Remove Microsoft Edge'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$edgePath = "$env:ProgramFiles(x86)\Microsoft\Edge\Application"
if (-not (Test-Path $edgePath)) {
    $edgePath = "$env:ProgramFiles\Microsoft\Edge\Application"
}
$installer = Get-ChildItem -Path $edgePath -Filter 'setup.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($installer) {
    Write-Output "Running Edge uninstaller: $($installer.FullName)"
    Start-Process -FilePath $installer.FullName -ArgumentList '--uninstall --system-level --verbose-logging --force-uninstall' -Wait -NoNewWindow
    Write-Output 'Microsoft Edge uninstall command executed.'
    Write-Output 'Note: Edge may re-install via Windows Update if not blocked via Group Policy.'
} else {
    Write-Output 'Edge installer not found. Edge may be already uninstalled or this is an ARM/non-standard install.'
}

$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
Set-ItemProperty -Path $policyPath -Name 'InstallDefault' -Value 0 -Type DWord -Force
Write-Output 'Edge auto-reinstall blocked via Group Policy registry.'
