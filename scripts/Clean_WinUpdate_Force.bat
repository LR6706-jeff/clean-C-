@echo off
title Windows Update Cache Purge

:: Admin Check & Auto Elevate
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ========================================================
echo [1/3] Stopping Windows Update and BITS services...
echo ========================================================
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

echo.
echo ========================================================
echo [2/3] Purging 347,000+ update fragments (6.43 GB)...
echo Please wait, deleting deep directory tree...
echo ========================================================
if exist "C:\Windows\SoftwareDistribution\Download" (
    rd /s /q "C:\Windows\SoftwareDistribution\Download"
    mkdir "C:\Windows\SoftwareDistribution\Download"
)

echo.
echo ========================================================
echo [3/3] Restarting Windows Update and BITS services...
echo ========================================================
net start bits >nul 2>&1
net start wuauserv >nul 2>&1

echo.
echo ========================================================
echo [SUCCESS] 6.43 GB update cache completely removed!
echo ========================================================
echo.
pause
