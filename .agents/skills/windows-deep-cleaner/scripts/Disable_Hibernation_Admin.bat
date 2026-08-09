@echo off
chcp 65001 >nul
:: Auto Elevate Script for Disabling Hibernation
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ======================================================
echo 正在为您关闭 Windows 休眠功能以清空 hiberfil.sys ...
echo ======================================================
powercfg -h off

echo.
echo [成功] 休眠功能已关闭！物理内存预留空间已释放。
echo.
pause
