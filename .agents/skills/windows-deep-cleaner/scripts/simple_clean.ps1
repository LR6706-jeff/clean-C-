# simple_clean.ps1
# Step 2: Targeted deep clean for Chinese Windows AppData hogs & Safe Caches
# IMPORTANT: English-only output to avoid PowerShell parser errors on Chinese Windows (TerminatorExpectedAtEndOfString).

$user = $env:USERPROFILE
$local = $env:LOCALAPPDATA
$app = $env:APPDATA

$before = (Get-PSDrive C).Free
Write-Host "--- Deep Clean Starting ---" -ForegroundColor Cyan

# --- 1. WPS Office: kill addons + browser-kernel cache ---
Write-Host "[1/7] WPS Office plugins and cache..." -ForegroundColor Yellow
$wpsProcesses = @("wps", "wpp", "et", "wpscloudsvr", "wpscenter")
foreach ($p in $wpsProcesses) { Stop-Process -Name $p -Force -ErrorAction SilentlyContinue }
if (Test-Path "$app\kingsoft") {
    Remove-Item "$app\kingsoft\wps\addons\*"   -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$app\kingsoft\office6\cache\*" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done" -ForegroundColor Green

# --- 2. AI Desktop Clients: Perplexity / IMA Copilot / Quark ---
Write-Host "[2/7] AI & Browser Desktop Client caches (Perplexity, ima.copilot, Quark)..." -ForegroundColor Yellow
Stop-Process -Name "Perplexity" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ima.copilot" -Force -ErrorAction SilentlyContinue
$aiPaths = @("$local\Perplexity", "$local\ima.copilot", "$local\Quark")
foreach ($path in $aiPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -Include "*Cache*", "*logs*" |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  Done" -ForegroundColor Green

# --- 3. Code Editors & Dev Caches (.cache, npm-cache, .codex, VS Code) ---
Write-Host "[3/7] Code editor & package caches (.cache, npm-cache, .codex, VS Code)..." -ForegroundColor Yellow
if (Test-Path "$user\.cache") { Remove-Item "$user\.cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "$local\npm-cache") { Remove-Item "$local\npm-cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "$user\.codex") { Remove-Item "$user\.codex\*" -Recurse -Force -ErrorAction SilentlyContinue }

$codePaths = @("$app\Code", "$app\CodeBuddy CN", "$user\.vscode")
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

# --- 4. Tencent Client Logs & Audio/Video Cache (Chat Data Safe) ---
Write-Host "[4/7] Tencent client logs & audio/video caches (xwechat logs, WeMeet, QQLive)..." -ForegroundColor Yellow
if (Test-Path "$app\Tencent\xwechat\log") {
    Remove-Item "$app\Tencent\xwechat\log\*" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path "$app\Tencent\WeMeet") {
    Get-ChildItem "$app\Tencent\WeMeet" -Recurse -Include "*Cache*", "*logs*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path "$app\Tencent\QQLive") {
    Remove-Item "$app\Tencent\QQLive\*" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done" -ForegroundColor Green

# --- 5. Windows Upgrade Residue ($WINDOWS.~BT) ---
Write-Host "[5/7] Windows upgrade residue (C:\$WINDOWS.~BT)..." -ForegroundColor Yellow
if (Test-Path "C:\`$WINDOWS.~BT") {
    Remove-Item "C:\`$WINDOWS.~BT" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done" -ForegroundColor Green

# --- 6. Antigravity / Gemini Brain Session Logs ---
Write-Host "[6/7] Antigravity IDE session brain logs (.gemini\antigravity-ide\brain)..." -ForegroundColor Yellow
if (Test-Path "$user\.gemini\antigravity-ide\brain") {
    Get-ChildItem "$user\.gemini\antigravity-ide\brain" -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
}
Write-Host "  Done" -ForegroundColor Green

# --- 7. Flash_Center bundleware ---
Write-Host "[7/7] Flash_Center bundleware leftovers..." -ForegroundColor Yellow
Stop-Process -Name "FlashCenter" -Force -ErrorAction SilentlyContinue
if (Test-Path "$local\Flash_Center") {
    Remove-Item "$local\Flash_Center\*" -Recurse -Force -ErrorAction SilentlyContinue
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
