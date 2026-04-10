param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'brave-debloat'
    Label         = 'Brave Debloat'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$regPaths = @(
    @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'MetricsReportingEnabled'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'PasswordManagerEnabled'; Value = 0 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveRewardsDisabled'; Value = 1 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveWalletDisabled'; Value = 1 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveVPNDisabled'; Value = 1 },
    @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveNewsDisabled'; Value = 1 }
)
foreach ($reg in $regPaths) {
    if (-not (Test-Path $reg.Path)) { New-Item -Path $reg.Path -Force | Out-Null }
    Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type DWord -Force
    Write-Output "Set: $($reg.Name) = $($reg.Value)"
}
Write-Output 'Brave debloat applied via Group Policy registry.'
