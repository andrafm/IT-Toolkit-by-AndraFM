param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-onedrive'
    Label         = 'Remove OneDrive'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

# Stop OneDrive process
$proc = Get-Process -Name 'OneDrive' -ErrorAction SilentlyContinue
if ($proc) {
    $proc | Stop-Process -Force
    Start-Sleep -Milliseconds 500
    Write-Output 'OneDrive process stopped.'
}

# Uninstall OneDrive
$paths = @(
    "$env:SystemRoot\System32\OneDriveSetup.exe",
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
    "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe"
)

$uninstalled = $false
foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Output "Running uninstaller: $path"
        Start-Process -FilePath $path -ArgumentList '/uninstall' -Wait -NoNewWindow
        $uninstalled = $true
        break
    }
}

if (-not $uninstalled) {
    Write-Output 'OneDrive installer not found. May already be removed or not installed.'
}

# Disable OneDrive via registry
$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'
if (-not (Test-Path $policyPath)) {
    New-Item -Path $policyPath -Force | Out-Null
}
Set-ItemProperty -Path $policyPath -Name 'DisableFileSyncNGSC' -Value 1 -Type DWord -Force
Write-Output 'OneDrive disabled via Group Policy registry.'

# Remove OneDrive from startup
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -ErrorAction SilentlyContinue
Write-Output 'OneDrive removed from startup entries.'
