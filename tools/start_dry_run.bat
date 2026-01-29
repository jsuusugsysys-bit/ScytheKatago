@echo off
echo ========================================
echo Scythe Detection Tool - DRY RUN MODE
echo ========================================
echo.
echo Dry-run mode: Detect only, no clicking
echo.
echo ========================================
echo.

"C:\Users\31437\AppData\Local\Programs\Python\Python312\python.exe" "%~dp0scythe_auto.py" --dry-run --no-confirm

pause
