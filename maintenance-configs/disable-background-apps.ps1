param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'disable-background-apps'
    Label         = 'Disable Background Apps'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'
if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
Set-ItemProperty -Path $path -Name 'GlobalUserDisabled' -Value 1 -Type DWord -Force
Set-ItemProperty -Path $path -Name 'Disabled' -Value 1 -Type DWord -Force
Write-Output 'Background apps disabled for current user.'

$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
Set-ItemProperty -Path $policyPath -Name 'LetAppsRunInBackground' -Value 2 -Type DWord -Force
Write-Output 'Background app run policy set to deny via Group Policy registry.'
