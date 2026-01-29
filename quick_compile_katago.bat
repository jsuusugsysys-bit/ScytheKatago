@echo off
echo ===== Quick Compile KataGo =====

REM Setup Visual Studio environment
echo [1/3] Setting up VS environment...
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
if %errorlevel% neq 0 (
    echo Trying VS 2019...
    call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Cannot find Visual Studio!
        pause
        exit /b 1
    )
)

REM Clean specific object files to force recompile
echo [2/3] Cleaning boardhistory.obj...
if exist "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\boardhistory.obj" (
    del "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\boardhistory.obj"
    echo Deleted boardhistory.obj
)

REM Build
echo [3/3] Building KataGo...
cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4

if %errorlevel% neq 0 (
    echo.
    echo ===== BUILD FAILED =====
    pause
    exit /b 1
)

echo.
echo ===== BUILD SUCCESS =====
dir /TC Release\katago.exe
echo.

REM Copy to scythe_lizzie directory
echo Copying katago.exe to scythe_lizzie...
copy /Y "Release\katago.exe" "D:\ScytheKatago\scythe_lizzie\katago.exe"

echo.
echo Done!
pause
