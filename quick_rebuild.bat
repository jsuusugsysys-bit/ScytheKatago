@echo off
echo ========================================
echo Quick Rebuild KataGo (After Code Fix)
echo ========================================
echo.

REM Set up Visual Studio environment
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

REM Add CMake to PATH
set "PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"

echo [1/1] Building KataGo...
cd /d "D:\ScytheKatago\KataGo\cpp\build"

cmake --build . --config Release --parallel 4

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS!
    echo ========================================
    echo.
    echo Output: D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe
    echo.
    echo Next: Test the scythe fix!
    echo.
) else (
    echo.
    echo ========================================
    echo FAILED!
    echo ========================================
    echo Check error messages above
)

pause
