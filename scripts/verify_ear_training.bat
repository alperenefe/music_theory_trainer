@echo off
REM Kulak egitimi modulu dogrulamasi: analyze + testler.
REM Cikti: build\verify_output.txt
cd /d "%~dp0.."
if not exist build mkdir build
echo [1/2] flutter analyze calisiyor...
call flutter analyze > build\verify_output.txt 2>&1
echo.>> build\verify_output.txt
echo ===== flutter test =====>> build\verify_output.txt
echo [2/2] flutter test calisiyor...
call flutter test >> build\verify_output.txt 2>&1
echo.
echo Bitti. Sonuclar: build\verify_output.txt
pause
