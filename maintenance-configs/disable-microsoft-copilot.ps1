param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'disable-microsoft-copilot'
    Label         = 'Disable Microsoft Copilot'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$regPaths = @(
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Value = 1 },
    @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Value = 1 },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowCopilotButton'; Value = 0 }
)

foreach ($reg in $regPaths) {
    if (-not (Test-Path $reg.Path)) {
        New-Item -Path $reg.Path -Force | Out-Null
    }
    Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type DWord -Force
    Write-Output "Set: $($reg.Path)\$($reg.Name) = $($reg.Value)"
}

Write-Output 'Microsoft Copilot disabled via Group Policy registry keys.'
Write-Output 'Note: A reboot or sign-out may be needed for full effect.'
