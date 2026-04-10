param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'edge-debloat'
    Label         = 'Edge Debloat'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$regPaths = @(
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'MetricsReportingEnabled'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'PersonalizationReportingEnabled'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeShoppingAssistantEnabled'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ShowMicrosoftRewards'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HubsSidebarEnabled'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'VerticalTabsAllowed'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'NewTabPageAllowedBackgroundTypes'; Value = 3 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DefaultBrowserSettingsCampaignEnabled'; Value = 0 }
)
foreach ($reg in $regPaths) {
    if (-not (Test-Path $reg.Path)) { New-Item -Path $reg.Path -Force | Out-Null }
    Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type DWord -Force
    Write-Output "Set: $($reg.Name) = $($reg.Value)"
}
Write-Output 'Edge debloat applied via Group Policy registry.'
