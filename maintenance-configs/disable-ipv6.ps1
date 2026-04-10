param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'disable-ipv6'
    Label         = 'Disable IPv6'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
foreach ($adapter in $adapters) {
    try {
        Disable-NetAdapterBinding -Name $adapter.Name -ComponentID 'ms_tcpip6' -ErrorAction SilentlyContinue
        Write-Output "IPv6 disabled on: $($adapter.Name)"
    } catch {
        Write-Output "Skipped: $($adapter.Name) - $($_.Exception.Message)"
    }
}
$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name 'DisabledComponents' -Value 0xFF -Type DWord -Force
Write-Output 'IPv6 globally disabled via registry.'
