@echo off
echo ===== Compiling KataGo =====

REM Setup Visual Studio environment (VS 18 = VS 2018/2019)
echo [1/2] Setting up VS environment...
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if %errorlevel% neq 0 (
    echo ERROR: Cannot find Visual Studio!
    exit /b 1
)

REM Build
echo [2/2] Building KataGo...
cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4

if %errorlevel% neq 0 (
    echo.
    echo ===== BUILD FAILED =====
    exit /b 1
)

echo.
echo ===== BUILD SUCCESS =====
dir Release\katago.exe
