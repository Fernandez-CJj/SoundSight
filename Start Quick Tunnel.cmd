@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0backend\start-tunnel.ps1"
if errorlevel 1 pause
endlocal
