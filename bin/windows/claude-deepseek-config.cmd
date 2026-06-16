@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0claude-deepseek-config.ps1" %*
endlocal
