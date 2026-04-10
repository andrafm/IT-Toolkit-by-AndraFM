param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'disable-storage-sense'
    Label         = 'Disable Storage Sense'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
Set-ItemProperty -Path $path -Name '01' -Value 0 -Type DWord -Force
Write-Output 'Storage Sense disabled.'
