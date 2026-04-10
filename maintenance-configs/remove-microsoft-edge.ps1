param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'remove-microsoft-edge'
    Label         = 'Remove Microsoft Edge'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

Write-Output 'Stopping Edge-related processes...'
Get-Process -Name 'msedge', 'msedgewebview2', 'MicrosoftEdgeUpdate' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $procName = $_.ProcessName
        $procId = $_.Id
        try {
            Stop-Process -Id $procId -Force -ErrorAction Stop
            Write-Output "Stopped process: $procName"
        }
        catch {
            Write-Output "Could not stop process: $procName"
        }
    }

$candidateRoots = @(
    "$env:ProgramFiles(x86)\Microsoft\Edge\Application",
    "$env:ProgramFiles\Microsoft\Edge\Application",
    "$env:LocalAppData\Microsoft\Edge\Application"
) | Select-Object -Unique

$installers = New-Object System.Collections.ArrayList
foreach ($root in $candidateRoots) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Filter 'setup.exe' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            ForEach-Object { [void]$installers.Add($_.FullName) }
    }
}

$installers = @($installers | Select-Object -Unique)

if ($installers.Count -eq 0) {
    Write-Output 'Edge installer not found. Edge may be already uninstalled or hidden by system protection.'
}
else {
    $attempted = $false
    foreach ($setupPath in $installers) {
        foreach ($scopeArg in @('--system-level', '--user-level')) {
            $attempted = $true
            $args = "--uninstall --msedge $scopeArg --verbose-logging --force-uninstall"
            Write-Output "Running Edge uninstaller: $setupPath $args"
            try {
                $proc = Start-Process -FilePath $setupPath -ArgumentList $args -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                Write-Output "Uninstaller exit code ($scopeArg): $($proc.ExitCode)"
            }
            catch {
                Write-Output "Uninstaller failed ($scopeArg): $($_.Exception.Message)"
            }
        }
    }

    if ($attempted) {
        Write-Output 'Microsoft Edge uninstall command(s) executed.'
    }
}

$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
Set-ItemProperty -Path $policyPath -Name 'InstallDefault' -Value 0 -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name 'UpdateDefault' -Value 0 -Type DWord -Force
Write-Output 'Edge auto-reinstall blocked via Group Policy registry.'

foreach ($svc in @('edgeupdate', 'edgeupdatem')) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($null -ne $service) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Output "Disabled service: $svc"
        }
        catch {
            Write-Output "Could not disable service: $svc"
        }
    }
}

Write-Output 'Catatan: Pada sebagian build Windows 10/11, Edge bisa tetap diproteksi oleh komponen sistem.'
