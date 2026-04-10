param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'prefer-ipv4-over-ipv6'
    Label         = 'Prefer IPv4 over IPv6'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name 'DisabledComponents' -Value 0x20 -Type DWord -Force
Write-Output 'IPv4 preferred over IPv6 (DisabledComponents = 0x20).'
