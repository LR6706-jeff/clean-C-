# 🧹 Windows Deep Cleaner Skill

> An AI agent skill for deep cleaning Windows C: drive — targeting the hidden AppData hogs that standard cleanup tools miss.

[![Platform](https://img.shields.io/badge/platform-Windows-blue)](https://www.microsoft.com/windows)
[![Shell](https://img.shields.io/badge/shell-PowerShell-5391FE)](https://docs.microsoft.com/powershell)
[![Language](https://img.shields.io/badge/skill-Antigravity--AI-brightgreen)](https://github.com/antigravity-ai)

---

## ✨ What This Does

Standard Windows cleanup tools (`Disk Cleanup`, `%temp%`) typically free **less than 1 GB**. The real space hogs hide in `AppData` — silently downloaded plugins, GPU render caches, AI client blobs, and bundleware leftovers.

This skill guides an AI agent through a two-phase process:
1. **Scan** — identify the top 20 largest directories in your user profile
2. **Clean** — surgically remove safe-to-delete caches without touching your settings or data

**Real-world result**: freed **5.3 GB** in a single session on a typical Chinese Windows dev machine.

---

## 📁 File Structure

```
windows-deep-cleaner/
├── SKILL.md                  # AI agent instructions (trigger conditions, workflow, gotchas)
└── scripts/
    ├── Get-DiskHogs.ps1      # Step 1: Scan & rank top 20 space consumers
    ├── simple_clean.ps1      # Step 2: Targeted AppData deep clean
    ├── Antigravity_Clean.ps1 # Full 12-category system clean (admin required)
    └── Antigravity_Clean.bat # One-click launcher with auto admin elevation
```

---

## 🎯 Targets

| Software | Path | Safe to Script? |
|---|---|---|
| **WPS Office** | `%APPDATA%\kingsoft\wps\addons` | ✅ Yes (kill process first) |
| **Perplexity** | `%LOCALAPPDATA%\Perplexity\*Cache*` | ✅ Yes |
| **IMA Copilot** | `%LOCALAPPDATA%\ima.copilot\*Cache*` | ✅ Yes |
| **VS Code** | `%APPDATA%\Code\**\Cache,GPUCache,logs` | ✅ Yes (settings safe) |
| **CodeBuddy** | `%APPDATA%\CodeBuddy CN\**\Cache` | ✅ Yes |
| **WeChat DevTools** | `%LOCALAPPDATA%\微信开发者工具\User Data\*\Cache` | ✅ Yes |
| **Flash_Center** | `%LOCALAPPDATA%\Flash_Center` | ✅ Nuke it |
| **WeChat / QQ / Lark** | `%APPDATA%\Tencent`, `%APPDATA%\LarkShell` | ⚠️ Use app's built-in storage manager |
| **JianyingPro (剪映)** | `%LOCALAPPDATA%\JianyingPro\User Data\Cache` | ✅ Yes (drafts unaffected) |
| **Notion** | `%APPDATA%\Notion` | ✅ Yes (cloud data safe) |

---

## 🚀 Quick Start

### Option A: One-click full system clean (Admin)
```
scripts\Antigravity_Clean.bat
```
Auto-elevates to admin, runs 12-category cleanup, reports freed space.

### Option B: Targeted AppData clean
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\simple_clean.ps1
```

### Option C: Scan only (see what's eating space first)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Get-DiskHogs.ps1
```

---

## ⚠️ Known Gotcha: Chinese Windows Encoding Bug

On Chinese Windows, **PowerShell script files that contain Chinese characters in `Write-Host` strings will crash** with `TerminatorExpectedAtEndOfString`, even if `chcp 65001` is set.

**Root cause**: The PowerShell parser misinterprets certain UTF-8 byte sequences in Chinese strings as unterminated string literals.

**Fix**: All scripts in this repo use **English-only output strings**. Do not add Chinese characters to `Write-Host` calls in `.ps1` files.

---

## 📋 12-Category System Clean (Antigravity_Clean.ps1)

| # | Category | Notes |
|---|---|---|
| 01 | Windows Temp + User Temp | Safe to nuke |
| 02 | Recycle Bin | |
| 03 | Windows Update Download Cache | Stops/restarts wuauserv |
| 04 | Delivery Optimization Cache | |
| 05 | Thumbnail Cache | Rebuilt automatically |
| 06 | Font Cache | Rebuilt on reboot |
| 07 | Crash Dumps + Error Reports | |
| 08 | Prefetch Files | |
| 09 | Old Log Files | CBS, DISM, MeasuredBoot |
| 10 | Edge Browser Cache | |
| 11 | Windows.old | Asks for confirmation |
| 12 | DISM Component Store | May take several minutes |

---

## 🔒 Safety Principles

- **Never** touch `%APPDATA%\WeChat` or `%APPDATA%\LarkShell` with a script (risk of chat history loss)
- For code editors, **only** remove cache subfolders — never the parent directory containing `settings.json`
- All cleanup scripts include `Stop-Process` guards before touching locked files
- `Windows.old` deletion requires explicit user confirmation

---

## 📜 License

MIT — use freely, contribute back your own target discoveries!
