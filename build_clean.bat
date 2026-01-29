@echo off
set LOG=D:\ScytheKatago\build_clean.log
echo [START] Clean Build Test > %LOG%

REM 1. Setup Environment
echo [ENV] Setting up Visual Studio Environment...
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Failed to find VS Environment!
    exit /b 1
)

REM 2. Prepare Directory
if not exist "D:\ScytheKatago\KataGo\cpp\build" mkdir "D:\ScytheKatago\KataGo\cpp\build"
cd /d "D:\ScytheKatago\KataGo\cpp\build"

REM Clean Cache
if exist CMakeCache.txt del CMakeCache.txt

REM 3. Configure
echo [CONFIG] Configuring CMake...
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib" >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Configuration Failed!
    exit /b 1
)

REM 4. Build
echo [BUILD] Building Executable...
cmake --build . --config Release --parallel 4 >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Build Failed!
    exit /b 1
)

echo [SUCCESS] Build Completed!
if exist "Release\katago.exe" (
    copy /Y "Release\katago.exe" "D:\ScytheKatago\katago_clean.exe" >> %LOG% 2>&1
    echo Success! File is at D:\ScytheKatago\katago_clean.exe
)
