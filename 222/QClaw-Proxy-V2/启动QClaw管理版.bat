@echo off
title QClaw Proxy V2 - Management Dashboard
cd /d "%~dp0"

echo [*] Checking dependencies...
pip install -r requirements.txt

echo [*] Starting QClaw Proxy V2...
echo [*] API Proxy (for Claude Code): http://localhost:18832
echo [*] Admin Dashboard (UI): http://localhost:18833
echo.
python app.py
pause
