param(
    [switch]$Execute
)

$config = [pscustomobject]@{
    Id            = 'fix-printer-spooler'
    Label         = 'Fix Printer Spooler'
    Group         = 'Fixes'
    RequiresAdmin = $true
}

if (-not $Execute) {
    return $config
}

$spoolPath = Join-Path $env:SystemRoot 'System32\spool\PRINTERS'

Write-Output '==============================='
Write-Output 'FIX PRINTER SPOOLER'
Write-Output '==============================='
 
$spooler = Get-Service -Name spooler -ErrorAction SilentlyContinue
if ($null -eq $spooler) {
    Write-Output 'Service Spooler tidak ditemukan di device ini. Skip.'
    return
}

Write-Output '[1] Stop Printer Spooler...'
Stop-Service -Name spooler -Force -ErrorAction SilentlyContinue

Write-Output '[2] Hapus file antrian printer...'
if (Test-Path -Path $spoolPath) {
    Remove-Item -Path (Join-Path $spoolPath '*') -Force -ErrorAction SilentlyContinue
}

Write-Output '[3] Start Printer Spooler...'
try {
    Start-Service -Name spooler -ErrorAction Stop
}
catch {
    Write-Output "Gagal start Spooler: $($_.Exception.Message)"
    return
}

Write-Output 'Selesai! Printer sudah di-refresh.'
