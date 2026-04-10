param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'disable-notification-tray-calendar'
    Label         = 'Disable Notification Tray/Calendar'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
Set-ItemProperty -Path $path -Name 'HideSCAMeetNow' -Value 1 -Type DWord -Force

$path2 = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
if (-not (Test-Path $path2)) { New-Item -Path $path2 -Force | Out-Null }
Set-ItemProperty -Path $path2 -Name 'HideRecentlyAddedApps' -Value 1 -Type DWord -Force

$path3 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
if (-not (Test-Path $path3)) { New-Item -Path $path3 -Force | Out-Null }
Set-ItemProperty -Path $path3 -Name 'HideSCAMeetNow' -Value 1 -Type DWord -Force

Write-Output 'Notification tray calendar and Meet Now button disabled.'
