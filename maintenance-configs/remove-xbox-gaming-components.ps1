param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-xbox-gaming-components'
    Label         = 'Remove Xbox & Gaming Components'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$packages = @(
    'Microsoft.XboxApp',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.XboxTCUI',
    'Microsoft.Xbox.TCUI',
    'Microsoft.GamingApp'
)

foreach ($pkg in $packages) {
    try {
        $found = Get-AppxPackage -Name $pkg -AllUsers -ErrorAction SilentlyContinue
        if ($found) {
            Remove-AppxPackage -Package $found.PackageFullName -AllUsers -ErrorAction SilentlyContinue
            Write-Output "Removed: $pkg"
        } else {
            Write-Output "Not installed: $pkg"
        }
    }
    catch {
        Write-Output "Skipped: $pkg - $($_.Exception.Message)"
    }
}

# Disable Xbox Game Bar via registry
$regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name 'AllowGameDVR' -Value 0 -Type DWord -Force
Write-Output 'Xbox Game DVR/Game Bar disabled via Group Policy registry.'

Write-Output 'Xbox and Gaming components removal completed.'
