@echo off
REM Run from project root: android\get_sha1.bat
REM Or from android folder: get_sha1.bat
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0get_sha1.ps1"
pause
