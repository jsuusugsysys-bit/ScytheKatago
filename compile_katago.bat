@echo off
chcp 65001 >nul
echo ========================================
echo Compiling KataGo (Scythe Fix)
echo ========================================
echo.

cd /d "d:\ScytheKatago\KataGo\cpp\build"

echo [1/1] Building KataGo...
cmake --build . --config Release --parallel 4

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS!
    echo ========================================
    echo.
    echo Output: d:\ScytheKatago\KataGo\cpp\build\Release\katago.exe
    echo.
) else (
    echo.
    echo ========================================
    echo FAILED!
    echo ========================================
    echo Check error messages above
)

pause
