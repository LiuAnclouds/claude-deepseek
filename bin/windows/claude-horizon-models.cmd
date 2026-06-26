@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\libexec\claude-horizon-models.ps1" %*
endlocal