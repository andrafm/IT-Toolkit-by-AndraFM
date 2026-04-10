param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'disable-teredo'
    Label         = 'Disable Teredo'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

netsh interface teredo set state disabled | Out-Null
Write-Output 'Teredo tunneling disabled via netsh.'

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
$current = (Get-ItemProperty -Path $regPath -Name 'DisabledComponents' -ErrorAction SilentlyContinue).DisabledComponents
if ($null -eq $current) { $current = 0 }
Set-ItemProperty -Path $regPath -Name 'DisabledComponents' -Value ($current -bor 0x08) -Type DWord -Force
Write-Output 'Teredo also disabled via registry DisabledComponents flag.'
