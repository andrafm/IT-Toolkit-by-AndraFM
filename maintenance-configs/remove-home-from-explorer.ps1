param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-home-from-explorer'
    Label         = 'Remove Home from Explorer'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
if (Test-Path $path) {
    Remove-Item -Path $path -Recurse -Force
    Write-Output 'Home removed from Explorer navigation pane.'
} else {
    Write-Output 'Home entry not found in registry (may already be removed).'
}

$path2 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
if (-not (Test-Path $path2)) { New-Item -Path $path2 -Force | Out-Null }
Set-ItemProperty -Path $path2 -Name 'LaunchTo' -Value 1 -Type DWord -Force
Write-Output 'Explorer set to open This PC instead of Home.'
