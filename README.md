# IT Toolkit by AndraFM_

Toolkit IT berbasis PowerShell GUI (Windows Forms) dengan arsitektur modular per aksi. Project ini mendukung eksekusi lokal maupun skenario remote `irm | iex`.

## Features

- GUI kategori: Maintenance, Networking, Security, Update
- Kategori Maintenance mendukung grouping `Basic` dan `Advanced`
- Preset `Recommended Selection` (Standart, Minimal, Clear)
- Loader untuk eksekusi remote via `bootstrap.ps1`
- Struktur modular: 1 script aksi = 1 file config

## Project Structure

- `ITToolkit.ps1` -> GUI utama
- `bootstrap.ps1` -> script loader untuk `irm | iex`
- `maintenance-configs/*.ps1` -> aksi maintenance
- `networking-configs/*.ps1` -> aksi networking
- `security-configs/*.ps1` -> aksi security
- `update-configs/*.ps1` -> aksi update

## Run Local

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\ITToolkit.ps1
```

## Run via IRM

Gunakan command berikut:

```powershell
irm "https://raw.githubusercontent.com/andrafirmansyah250699-ship-it/IT-Toolkit-by-AndraFM/master/bootstrap.ps1" | iex
```

## Screenshot

Tambahkan screenshot UI ke repo jika diperlukan, misalnya di `docs/images/`.

## Security Notes

- Gunakan hanya URL script yang kamu kontrol.
- Untuk production, pin ke tag rilis (mis. `v2.1.0`) agar tidak bergantung pada branch mutable.
- Tambahkan checksum validation jika mau hardening lebih lanjut.
- Opsi terbaik: gunakan code signing certificate.

## Release

- Current release: `v2.1.0`

