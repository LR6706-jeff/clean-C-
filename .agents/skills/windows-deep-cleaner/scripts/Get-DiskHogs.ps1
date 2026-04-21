# Get-DiskHogs.ps1
# Step 1: Scan for the top 20 largest directories in AppData / UserProfile
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File Get-DiskHogs.ps1
# IMPORTANT: Script must stay English-only to avoid PowerShell encoding parse errors on Chinese Windows.

$user = $env:USERPROFILE
Write-Host "Scanning C: for deep disk hogs..." -ForegroundColor Cyan

$results = @()
$dirsToScan = @("$user\AppData\Roaming", "$user\AppData\Local", $user)

foreach ($root in $dirsToScan) {
    if (Test-Path $root) {
        Get-ChildItem $root -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | ForEach-Object {
            if ($root -eq $user -and $_.Name -eq "AppData") { return }
            $sz = (Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                   Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
            if ($sz) { $results += [PSCustomObject]@{ Source = $root; Name = $_.Name; Size = $sz } }
        }
    }
}

Write-Host ""
Write-Host "Top 20 Space Consumers (>200 MB):" -ForegroundColor White
$results | Sort-Object Size -Descending | Select-Object -First 20 | ForEach-Object {
    $mb = $_.Size / 1MB
    if ($mb -gt 200) {
        $color = if ($mb -gt 1024) { "Red" } else { "Yellow" }
        Write-Host ("[{0,-40}] {1,8:N1} MB" -f ($_.Source + "\" + $_.Name), $mb) -ForegroundColor $color
    }
}
Write-Host ""
Write-Host "Scan complete. Review results and use simple_clean.ps1 to clean safe targets." -ForegroundColor Cyan
