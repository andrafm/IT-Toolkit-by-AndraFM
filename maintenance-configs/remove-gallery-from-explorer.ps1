param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-gallery-from-explorer'
    Label         = 'Remove Gallery from Explorer'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'
if (Test-Path $path) {
    Remove-Item -Path $path -Recurse -Force
    Write-Output 'Gallery removed from Explorer navigation pane.'
} else {
    Write-Output 'Gallery entry not found in registry (may already be removed).'
}
