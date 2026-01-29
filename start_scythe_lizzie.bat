@echo off
cd /d "%~dp0scythe_lizzie"

echo Starting Scythe Lizzieyzy...
echo Working directory: %CD%
echo.

java -jar lizzie-yzy2.5.3-shaded.jar

if errorlevel 1 (
    echo.
    echo Startup failed!
    pause
)
