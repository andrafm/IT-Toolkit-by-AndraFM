param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'set-display-for-performance'
    Label         = 'Set Display for Performance'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

# Set Visual Effects to 'Adjust for best performance'
$path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
Set-ItemProperty -Path $path -Name 'VisualFXSetting' -Value 2 -Type DWord -Force

$path2 = 'HKCU:\Control Panel\Desktop'
Set-ItemProperty -Path $path2 -Name 'DragFullWindows' -Value '0' -Force
Set-ItemProperty -Path $path2 -Name 'FontSmoothing' -Value '0' -Force
Set-ItemProperty -Path $path2 -Name 'UserPreferencesMask' -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force

Write-Output 'Display configured for best performance (visual effects minimized).'
