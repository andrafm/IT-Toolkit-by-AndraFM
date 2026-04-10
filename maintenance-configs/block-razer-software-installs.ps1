param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'block-razer-software-installs'
    Label         = 'Block Razer Software Installs'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$razerTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like '*Razer*' } -ErrorAction SilentlyContinue
foreach ($task in $razerTasks) {
    try {
        Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
        Write-Output "Disabled scheduled task: $($task.TaskName)"
    } catch {}
}

$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$razerDomains = @(
    '0.0.0.0 manifest.razer.com',
    '0.0.0.0 synapse3.razer.com'
)
$existing = Get-Content $hosts -Raw
$added = 0
foreach ($entry in $razerDomains) {
    if ($existing -notmatch [regex]::Escape($entry.Split(' ')[1])) {
        Add-Content -Path $hosts -Value $entry
        $added++
    }
}
$razerServices = Get-Service | Where-Object { $_.Name -like '*Razer*' }
foreach ($svc in $razerServices) {
    try {
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Output "Disabled Razer service: $($svc.Name)"
    } catch {}
}
Write-Output "Razer auto-install block applied. Hosts entries added: $added"
