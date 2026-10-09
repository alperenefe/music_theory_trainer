@echo off
REM Muzik Teorisi: build + telefona kur. Log: build\phone_install_log.txt
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0telefona_yukle.ps1"
echo.
echo Bitti. Log: build\phone_install_log.txt
pause
