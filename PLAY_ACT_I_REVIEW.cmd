@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "tools\Start-ActIHumanPlaytest.ps1" -RefreshAutomatedReport -ResetNarrativeState
exit /b %ERRORLEVEL%
