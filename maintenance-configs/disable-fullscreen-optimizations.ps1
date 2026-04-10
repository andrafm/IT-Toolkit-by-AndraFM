param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'disable-fullscreen-optimizations'
    Label         = 'Disable Fullscreen Optimizations'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$regPath = 'HKCU:\System\GameConfigStore'
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name 'GameDVR_FSEBehaviorMode' -Value 2 -Type DWord -Force
Set-ItemProperty -Path $regPath -Name 'GameDVR_HonorUserFSEBehaviorMode' -Value 1 -Type DWord -Force
Set-ItemProperty -Path $regPath -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Value 1 -Type DWord -Force
Set-ItemProperty -Path $regPath -Name 'GameDVR_EFSEFeatureFlags' -Value 0 -Type DWord -Force
Write-Output 'Fullscreen optimizations disabled via registry.'
