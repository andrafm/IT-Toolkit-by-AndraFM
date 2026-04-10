param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'adobe-network-block'
    Label         = 'Adobe Network Block'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$adobeDomains = @(
    '0.0.0.0 activate.adobe.com',
    '0.0.0.0 practivate.adobe.com',
    '0.0.0.0 ereg.adobe.com',
    '0.0.0.0 activate.wip.adobe.com',
    '0.0.0.0 3dns.adobe.com',
    '0.0.0.0 3dns-1.adobe.com',
    '0.0.0.0 3dns-2.adobe.com',
    '0.0.0.0 3dns-3.adobe.com',
    '0.0.0.0 adobe-dns.adobe.com',
    '0.0.0.0 adobe-dns-1.adobe.com',
    '0.0.0.0 adobe-dns-2.adobe.com',
    '0.0.0.0 lmlicenses.wip4.adobe.com',
    '0.0.0.0 lm.licenses.adobe.com'
)

$existing = Get-Content $hosts -Raw
$added = 0
foreach ($entry in $adobeDomains) {
    if ($existing -notmatch [regex]::Escape($entry.Split(' ')[1])) {
        Add-Content -Path $hosts -Value $entry
        $added++
    }
}
Write-Output "Adobe network block applied. Added $added new entries to hosts file."
