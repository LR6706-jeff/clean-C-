# simple_clean.ps1
# Step 2: Targeted deep clean for Chinese Windows AppData hogs
# Targets: WPS Office, Perplexity, IMA Copilot, VS Code, CodeBuddy, WeChat DevTools, Flash_Center
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File simple_clean.ps1
# IMPORTANT: English-only output to avoid PowerShell parser errors on Chinese Windows (TerminatorExpectedAtEndOfString).

$before = (Get-PSDrive C).Free
Write-Host "--- Deep Clean Starting ---" -ForegroundColor Cyan

# --- 1. WPS Office: kill addons + browser-kernel cache ---
Write-Host "[1/5] WPS Office plugins and cache..." -ForegroundColor Yellow
$wpsProcesses = @("wps", "wpp", "et", "wpscloudsvr", "wpscenter")
foreach ($p in $wpsProcesses) { Stop-Process -Name $p -Force -ErrorAction SilentlyContinue }
$wpsPath = "$env:APPDATA\kingsoft"
if (Test-Path $wpsPath) {
    Remove-Item "$wpsPath\wps\addons\*"   -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$wpsPath\office6\cache\*" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done" -ForegroundColor Green

# --- 2. AI Desktop Clients: Perplexity / IMA Copilot ---
Write-Host "[2/5] AI Desktop Client caches (Perplexity, ima.copilot)..." -ForegroundColor Yellow
Stop-Process -Name "Perplexity" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ima.copilot" -Force -ErrorAction SilentlyContinue
$aiPaths = @("$env:LOCALAPPDATA\Perplexity", "$env:LOCALAPPDATA\ima.copilot")
foreach ($path in $aiPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -Include "*Cache*", "*logs*" |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  Done" -ForegroundColor Green

# --- 3. Code Editors: VS Code / CodeBuddy (settings-safe) ---
Write-Host "[3/5] Code editor caches (VS Code, CodeBuddy)..." -ForegroundColor Yellow
$codePaths = @("$env:APPDATA\Code", "$env:APPDATA\CodeBuddy CN", "$env:USERPROFILE\.vscode")
foreach ($path in $codePaths) {
    if (Test-Path $path) {
        $targets = @("Cache", "Code Cache", "CachedData", "CachedExtensionVSIXs", "GPUCache", "logs")
        foreach ($t in $targets) {
            Get-ChildItem -Path $path -Filter $t -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
Write-Host "  Done" -ForegroundColor Green

# --- 4. WeChat DevTools compile cache ---
Write-Host "[4/5] WeChat DevTools compile cache..." -ForegroundColor Yellow
Stop-Process -Name "wechatdevtools" -Force -ErrorAction SilentlyContinue
$wechatDevPath = "$env:LOCALAPPDATA\微信开发者工具\User Data"
if (Test-Path $wechatDevPath) {
    Remove-Item "$wechatDevPath\*\Cache\*"      -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$wechatDevPath\*\Code Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done" -ForegroundColor Green

# --- 5. Flash_Center bundleware ---
Write-Host "[5/5] Flash_Center bundleware leftovers..." -ForegroundColor Yellow
Stop-Process -Name "FlashCenter" -Force -ErrorAction SilentlyContinue
$flashPath = "$env:LOCALAPPDATA\Flash_Center"
if (Test-Path $flashPath) {
    Remove-Item "$flashPath\*" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done" -ForegroundColor Green

# --- Summary ---
$after   = (Get-PSDrive C).Free
$freedMB = [Math]::Round(($after - $before) / 1MB, 2)
$afterGB = [Math]::Round($after / 1GB, 2)
Write-Host ""
Write-Host "Cleanup complete!" -ForegroundColor Cyan
Write-Host "Space freed: $freedMB MB"
Write-Host "C: free now: $afterGB GB"
