# 🧰 IT Toolkit by AndraFM_

Toolkit IT berbasis PowerShell GUI (Windows Forms) dengan struktur modular dan support remote execution.

---

## ⚡ Quick Start

Jalankan langsung via PowerShell:

```powershell
irm https://raw.githubusercontent.com/andrafm/IT-Toolkit-by-AndraFM/master/i.ps1 | iex 

```

✨ Features
- GUI berbasis kategori (Maintenance, Config, Security, Update)
- Modular script (1 aksi = 1 file)
- Preset recommended (Standard / Minimal / Clear)
- Support local & remote execution
- Bootstrap loader untuk auto setup

📁 Project Structure
- ITToolkit.ps1 → GUI utama
- bootstrap.ps1 → loader utama (IRM installer)
- maintenance-configs/ → script maintenance
- config-configs/ → script config & fixes
- security-configs/ → script security tools
- update-configs/ → script update tools

💻 Run Local
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\ITToolkit.ps1
```

🔐 Security Notes
- Jalankan hanya dari repository yang kamu percaya
- Disarankan gunakan pinned release untuk produksi
- Gunakan PowerShell ExecutionPolicy Bypass hanya saat diperlukan
- Untuk production, gunakan code signing jika memungkinkan

📌 Version
Current: v2.1.0
