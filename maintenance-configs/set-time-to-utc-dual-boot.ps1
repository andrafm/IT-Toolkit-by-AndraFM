param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'set-time-to-utc-dual-boot'
    Label         = 'Set Time to UTC (Dual Boot)'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
Set-ItemProperty -Path $path -Name 'RealTimeIsUniversal' -Value 1 -Type DWord -Force
Write-Output 'RealTimeIsUniversal registry key set to 1.'
Write-Output 'Windows will now read hardware clock as UTC, fixing dual-boot time sync with Linux.'
