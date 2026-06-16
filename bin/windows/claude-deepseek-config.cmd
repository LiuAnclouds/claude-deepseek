@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\libexec\claude-deepseek-config.ps1" %*
endlocal
