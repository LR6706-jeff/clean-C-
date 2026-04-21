# Antigravity Deep Clean v3.0
# Full 12-category Windows system drive cleanup
# Usage: Run Antigravity_Clean.bat as Administrator (auto-elevates)
# Or: powershell -NoProfile -ExecutionPolicy Bypass -File Antigravity_Clean.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'SilentlyContinue'

# Auto-elevate to admin if needed
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Helper: get total size of folder list
function Get-FolderSize($paths) {
    $total = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $s = (Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            if ($s) { $total += $s }
        }
    }
    return $total
}

function Format-Bytes($bytes) {
    if (!$bytes -or $bytes -le 0) { return "0 B" }
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { return "{0:N1} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { return "{0:N0} KB" -f ($bytes / 1KB) }
    else { return "$bytes B" }
}

function Get-DiskFree {
    $d = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($d) { return $d.Free }
    return 0
}

function Clean-Step {
    param([string]$Label, [string[]]$Dirs, [string[]]$Paths)
    Write-Host "  +-- $Label" -ForegroundColor Yellow
    $before = Get-FolderSize $Dirs
    foreach ($p in $Paths) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue }
    $after  = Get-FolderSize $Dirs
    $freed  = [Math]::Max(0, $before - $after)
    $color  = if ($freed -gt 0) { "Green" } else { "DarkGray" }
    Write-Host "  +-- OK  Freed: $(Format-Bytes $freed)" -ForegroundColor $color
    Write-Host ""
    return $freed
}

# ── Main ─────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "    Antigravity Deep Clean v3.0" -ForegroundColor Cyan
Write-Host "    12-category system drive cleanup" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""

$diskBefore = Get-DiskFree
Write-Host "  [Before] C: Free: $(Format-Bytes $diskBefore)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ------------- Starting Cleanup -------------" -ForegroundColor DarkCyan
Write-Host ""

$total = 0

# 01 Windows Temp / User Temp
$total += Clean-Step -Label "[01] Windows Temp + User Temp" `
    -Dirs  @("C:\Windows\Temp", "$env:LOCALAPPDATA\Temp") `
    -Paths @("C:\Windows\Temp\*", "$env:LOCALAPPDATA\Temp\*")

# 02 Recycle Bin
Write-Host "  +-- [02] Recycle Bin" -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "  +-- OK  Recycle Bin emptied" -ForegroundColor Green
Write-Host ""

# 03 Windows Update download cache
Write-Host "  +-- [03] Windows Update Download Cache" -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
$b3 = Get-FolderSize @("C:\Windows\SoftwareDistribution\Download")
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
$f3 = [Math]::Max(0, $b3 - (Get-FolderSize @("C:\Windows\SoftwareDistribution\Download")))
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Write-Host "  +-- OK  Freed: $(Format-Bytes $f3)" -ForegroundColor $(if ($f3 -gt 0) { "Green" } else { "DarkGray" })
Write-Host ""
$total += $f3

# 04 Delivery Optimization
$total += Clean-Step -Label "[04] Delivery Optimization Cache" `
    -Dirs  @("C:\Windows\SoftwareDistribution\DeliveryOptimization") `
    -Paths @("C:\Windows\SoftwareDistribution\DeliveryOptimization\*")

# 05 Thumbnail cache
Write-Host "  +-- [05] Thumbnail Cache" -ForegroundColor Yellow
$thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
$b5 = Get-FolderSize @($thumbPath)
Get-ChildItem -Path $thumbPath -Filter "thumbcache_*.db" -Force -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
$f5 = [Math]::Max(0, $b5 - (Get-FolderSize @($thumbPath)))
Write-Host "  +-- OK  Freed: $(Format-Bytes $f5)" -ForegroundColor $(if ($f5 -gt 0) { "Green" } else { "DarkGray" })
Write-Host ""
$total += $f5

# 06 Font cache
Write-Host "  +-- [06] Font Cache" -ForegroundColor Yellow
Stop-Service -Name "FontCache" -Force -ErrorAction SilentlyContinue
$fontCache = "$env:windir\ServiceProfiles\LocalService\AppData\Local\FontCache"
$b6 = Get-FolderSize @($fontCache)
Remove-Item "$fontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:windir\System32\FNTCACHE.DAT" -Force -ErrorAction SilentlyContinue
$f6 = [Math]::Max(0, $b6 - (Get-FolderSize @($fontCache)))
Start-Service -Name "FontCache" -ErrorAction SilentlyContinue
Write-Host "  +-- OK  Freed: $(Format-Bytes $f6)  (rebuilt on reboot)" -ForegroundColor $(if ($f6 -gt 0) { "Green" } else { "DarkGray" })
Write-Host ""
$total += $f6

# 07 Crash dumps + error reports
$total += Clean-Step -Label "[07] Crash Dumps + Error Reports" `
    -Dirs  @("C:\Windows\Minidump",
             "C:\ProgramData\Microsoft\Windows\WER\ReportArchive",
             "C:\ProgramData\Microsoft\Windows\WER\ReportQueue",
             "$env:LOCALAPPDATA\Microsoft\Windows\WER") `
    -Paths @("C:\Windows\Minidump\*",
             "C:\Windows\MEMORY.DMP",
             "C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*",
             "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*",
             "$env:LOCALAPPDATA\Microsoft\Windows\WER\*")

# 08 Prefetch
$total += Clean-Step -Label "[08] Prefetch Files" `
    -Dirs  @("C:\Windows\Prefetch") `
    -Paths @("C:\Windows\Prefetch\*.pf")

# 09 Old log files (safe subset only)
$total += Clean-Step -Label "[09] Old Log Files (safe subset)" `
    -Dirs  @("C:\Windows\Logs\CBS", "C:\Windows\Logs\DISM", "C:\Windows\Logs\MeasuredBoot", "C:\Windows\inf") `
    -Paths @("C:\Windows\Logs\CBS\*.log", "C:\Windows\Logs\DISM\*.log",
             "C:\Windows\Logs\MeasuredBoot\*.log", "C:\Windows\inf\*.log",
             "C:\Windows\WindowsUpdate.log")

# 10 Edge browser cache
$total += Clean-Step -Label "[10] Edge Browser Cache" `
    -Dirs  @("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
             "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache") `
    -Paths @("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
             "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*",
             "$env:LOCALAPPDATA\Microsoft\Internet Explorer\*",
             "$env:TEMP\Low\*")

# 11 Windows.old (confirm before delete)
$wold = "C:\Windows.old"
if (Test-Path $wold) {
    $b11 = Get-FolderSize @($wold)
    Write-Host "  +-- [11] Windows.old found! Size: $(Format-Bytes $b11)" -ForegroundColor Yellow
    Write-Host "  |   WARNING: Cannot be recovered once deleted." -ForegroundColor Red
    Write-Host "  |   Delete it? (Y to confirm, Enter to skip): " -ForegroundColor Red -NoNewline
    $ans = Read-Host
    if ($ans -match '^[Yy]$') {
        Dism.exe /Online /Cleanup-Image /SPSuperseded 2>&1 | Out-Null
        Remove-Item $wold -Recurse -Force -ErrorAction SilentlyContinue
        $f11 = [Math]::Max(0, $b11 - (Get-FolderSize @($wold)))
        Write-Host "  +-- OK  Freed: $(Format-Bytes $f11)" -ForegroundColor Green
        $total += $f11
    } else {
        Write-Host "  +-- Skipped (Windows.old kept)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  +-- [11] Windows.old: not found, skipping" -ForegroundColor DarkGray
}
Write-Host ""

# 12 DISM component cleanup
Write-Host "  +-- [12] DISM Component Store Cleanup (may take minutes)" -ForegroundColor Yellow
Dism.exe /Online /Cleanup-Image /StartComponentCleanup 2>&1 | Out-Null
Write-Host "  +-- OK  Component store optimized" -ForegroundColor Green
Write-Host ""

# Flush DNS
Write-Host "  +-- [+] Flush DNS Cache" -ForegroundColor DarkGray
ipconfig /flushdns 2>&1 | Out-Null
Write-Host "  +-- OK  DNS cache flushed" -ForegroundColor DarkGray
Write-Host ""

# Summary
$diskAfter  = Get-DiskFree
$totalFreed = [Math]::Max(0, $diskAfter - $diskBefore)

Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "    Cleanup Complete - Summary" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ("  Items cleaned: {0}" -f (Format-Bytes $total)) -ForegroundColor White
Write-Host ("  Free before:   {0}" -f (Format-Bytes $diskBefore)) -ForegroundColor White
Write-Host ("  Free after:    {0}" -f (Format-Bytes $diskAfter)) -ForegroundColor White
Write-Host ("  Net freed:     {0}" -f (Format-Bytes $totalFreed)) -ForegroundColor Green
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Note: Font cache will rebuild on next reboot." -ForegroundColor DarkGray
Write-Host ""
