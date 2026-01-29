@echo off
setlocal enabledelayedexpansion

echo === Scythe KataGo Build Script ===
echo.

REM Set VS environment (all paths in double quotes)
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 (
    echo ERROR: Failed to initialize VS environment
    exit /b 1
)

REM Build KataGo (all paths in double quotes)
echo.
echo === Building KataGo ===
cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4
if errorlevel 1 (
    echo ERROR: KataGo build failed
    exit /b 1
)

echo.
echo === Copying katago.exe ===
copy /Y "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe" "D:\ScytheKatago\scythe_lizzie\"
if errorlevel 1 (
    echo ERROR: Failed to copy katago.exe
    exit /b 1
)

echo.
echo === Build complete ===
echo katago.exe copied to scythe_lizzie
