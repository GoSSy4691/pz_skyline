@echo off
setlocal
title Project Zomboid - Mod Setup
color 07
set "PZ_SETUP_POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PZ_SETUP_POWERSHELL=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PZ_SETUP_POWERSHELL%" (
    echo Windows PowerShell was not found on this PC.
    pause
    exit /b 1
)
"%PZ_SETUP_POWERSHELL%" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Start-PZModSetup.ps1"
if errorlevel 1 (
    echo.
    echo Setup could not finish. The error is shown above.
    pause
    exit /b 1
)
endlocal
