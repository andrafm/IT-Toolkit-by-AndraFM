param(
    [switch]
    $Execute
)

$config = [pscustomobject]@{
    Id            = 'set-classic-right-click-menu'
    Label         = 'Set Classic Right-Click Menu'
    Group         = 'Advanced'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$path = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
Set-ItemProperty -Path $path -Name '(Default)' -Value '' -Force
Write-Output 'Classic right-click context menu restored.'
Write-Output 'Note: Explorer restart or sign-out/in may be needed to apply.'
Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
Start-Process 'explorer.exe'
