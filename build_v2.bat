@echo off
set LOG=D:\ScytheKatago\build_v2.log
echo [Start] Build V2 > %LOG% 2>&1

REM 1. Setup Environment
echo [1/4] Setting up environment... >> %LOG% 2>&1
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [Error] VCVARS failed >> %LOG% 2>&1
    exit /b 1
)

REM 2. Clean Specific Files (Force Rebuild of changed files)
echo [2/4] Cleaning specific objects... >> %LOG% 2>&1
if exist "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\gtp.obj" del "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\gtp.obj"
if exist "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\boardhistory.obj" del "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\boardhistory.obj"

cd /d "D:\ScytheKatago\KataGo\cpp\build"

REM 3. Configure (Fast, assume cache is mostly ok, but ensure libs are set)
echo [3/4] Configuring... >> %LOG% 2>&1
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib" >> %LOG% 2>&1

REM 4. Build
echo [4/4] Building... >> %LOG% 2>&1
cmake --build . --config Release --verbose >> %LOG% 2>&1

if %errorlevel% neq 0 (
    echo [FAILURE] Build Failed! >> %LOG% 2>&1
) else (
    echo [SUCCESS] Build Succeeded! >> %LOG% 2>&1
    if exist "Release\katago.exe" (
        copy /Y "Release\katago.exe" "D:\ScytheKatago\katago.exe" >> %LOG% 2>&1
        echo Copied to D:\ScytheKatago\katago.exe >> %LOG% 2>&1
    )
)
echo [End] >> %LOG% 2>&1
