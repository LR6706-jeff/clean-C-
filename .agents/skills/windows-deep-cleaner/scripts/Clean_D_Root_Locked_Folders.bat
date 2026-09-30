@echo off
title Purge Locked Root Folders on D:

:: Admin Check & Auto Elevate (Keep window open)
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ========================================================
echo   Taking Ownership and Purging Locked Folders on D:
echo ========================================================
echo.

echo [1/4] Processing D:\WindowsApps ...
takeown /F "D:\WindowsApps" /A /R /D Y
icacls "D:\WindowsApps" /grant administrators:F /T /C /Q
rd /s /q "D:\WindowsApps"

echo.
echo [2/4] Processing D:\DeliveryOptimization ...
takeown /F "D:\DeliveryOptimization" /A /R /D Y
icacls "D:\DeliveryOptimization" /grant administrators:F /T /C /Q
rd /s /q "D:\DeliveryOptimization"

echo.
echo [3/4] Processing D:\Config.Msi ...
takeown /F "D:\Config.Msi" /A /R /D Y
icacls "D:\Config.Msi" /grant administrators:F /T /C /Q
rd /s /q "D:\Config.Msi"

echo.
echo [4/4] Processing D:\Program Files\ModifiableWindowsApps ...
takeown /F "D:\Program Files\ModifiableWindowsApps" /A /R /D Y
icacls "D:\Program Files\ModifiableWindowsApps" /grant administrators:F /T /C /Q
rd /s /q "D:\Program Files\ModifiableWindowsApps"

echo.
echo ========================================================
echo   Cleanup Finished!
echo ========================================================
pause
