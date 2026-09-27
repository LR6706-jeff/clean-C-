# Get-DiskHogs.ps1
# Step 1: Scan for top disk consumers and deep hidden cache hogs
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File Get-DiskHogs.ps1
# IMPORTANT: Script must stay English-only to avoid PowerShell encoding parse errors on Chinese Windows.

$user = $env:USERPROFILE
$local = $env:LOCALAPPDATA
$app = $env:APPDATA

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Scanning C: for Deep Disk Hogs" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Helper function to get directory size safely
function Get-FolderSizeSafe($path) {
    if (Test-Path $path) {
        $s = (Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
        if ($s) { return $s }
    }
    return 0
}

# --- 1. Targeted Probing for Known High-Value Hogs ---
Write-Host "[1] Checking Known High-Impact Deep Targets..." -ForegroundColor White

$specialTargets = @(
    @{ Name = "Edge Service Worker Cache"; Path = "$local\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage" },
    @{ Name = "Windows Update Download Cache"; Path = "C:\Windows\SoftwareDistribution\Download" },
    @{ Name = "WeChat DevTools Build Cache"; Path = "$local\微信开发者工具\User Data" },
    @{ Name = "WXWork (Enterprise WeChat) Caches"; Path = "$app\Tencent\WXWork" },
    @{ Name = "VS Code Dumps & WebStorage"; Path = "$app\Code\WebStorage" },
    @{ Name = "VS Code Crash Dumps (Crashpad)"; Path = "$app\Code\Crashpad" },
    @{ Name = "Antigravity IDE Old Backups"; Path = "$user\.gemini\antigravity-backup" },
    @{ Name = "Antigravity IDE Brain Logs"; Path = "$user\.gemini\antigravity-ide\brain" },
    @{ Name = "Tencent xwechat Logs"; Path = "$app\Tencent\xwechat\log" },
    @{ Name = "WPS Office Addons & Kernel Cache"; Path = "$app\kingsoft\wps\addons" },
    @{ Name = "Downloads Folder (User)"; Path = "$user\Downloads" }
)

foreach ($target in $specialTargets) {
    $size = Get-FolderSizeSafe $target.Path
    $mb = [math]::Round($size / 1MB, 1)
    if ($mb -gt 100) {
        $color = if ($mb -gt 1024) { "Red" } else { "Yellow" }
        Write-Host ("  -> [{0,-35}] {1,8:N1} MB" -f $target.Name, $mb) -ForegroundColor $color
    }
}

Write-Host ""
# --- 2. Top-level Consumers in User Profile and AppData ---
Write-Host "[2] Top 15 Space Consumers in User Profile (>300 MB):" -ForegroundColor White

$results = @()
$dirsToScan = @("$app", "$local", $user)

foreach ($root in $dirsToScan) {
    if (Test-Path $root) {
        Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | ForEach-Object {
            if ($root -eq $user -and $_.Name -eq "AppData") { return }
            $sz = (Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                   Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
            if ($sz) { $results += [PSCustomObject]@{ Source = $root; Name = $_.Name; Size = $sz } }
        }
    }
}

$results | Sort-Object Size -Descending | Select-Object -First 15 | ForEach-Object {
    $mb = $_.Size / 1MB
    if ($mb -gt 300) {
        $color = if ($mb -gt 1024) { "Red" } else { "Yellow" }
        Write-Host ("  [{0,-40}] {1,8:N1} MB" -f ($_.Source + "\" + $_.Name), $mb) -ForegroundColor $color
    }
}

$cDrive = Get-PSDrive C
$freeGB = [math]::Round($cDrive.Free / 1GB, 2)
Write-Host ""
Write-Host ("C: Current Free Space: {0} GB" -f $freeGB) -ForegroundColor Cyan
Write-Host "Scan complete. Use simple_clean.ps1 or specialized scripts to clean." -ForegroundColor Cyan
