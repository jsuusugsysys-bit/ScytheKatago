@echo off
REM Run scythe search tests
REM This script tests the scythe trigger functionality in search tree

echo ========================================
echo Scythe Search Tests
echo ========================================
echo.

cd /d D:\ScytheKatago\KataGo\cpp\build

echo Building KataGo with tests...
cmake --build . --config Release --parallel 4
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Running Scythe Search Tests...
echo ========================================
echo.

Release\katago.exe runtests -scythe-search
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Tests failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo All tests passed!
echo ========================================
pause
