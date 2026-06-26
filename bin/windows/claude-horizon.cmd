@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\libexec\claude-horizon.ps1" %*
endlocal