@echo off
echo [STATUS] Checking Environment...

REM 1. Call VS Environment
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if %errorlevel% neq 0 (
    echo [CRITICAL ERROR] Failed to call vcvars64.bat
    exit /b 1
)

REM 2. Check Compiler
where cl.exe
if %errorlevel% neq 0 (
    echo [CRITICAL ERROR] cl.exe not found! Environment setup failed.
    exit /b 1
) else (
    echo [SUCCESS] Compiler found.
)

REM 3. Set CMake Path explicitly
set "PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
where cmake.exe
if %errorlevel% neq 0 (
    echo [CRITICAL ERROR] cmake.exe not found!
    exit /b 1
)

REM 4. Clean and Config
echo [STATUS] Configuring CMake...
cd /d "D:\ScytheKatago\KataGo\cpp\build"
if exist CMakeCache.txt del CMakeCache.txt

cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib"
if %errorlevel% neq 0 (
    echo [CRITICAL ERROR] CMake Configuration Failed!
    exit /b 1
)

REM 5. Build
echo [STATUS] Building...
cmake --build . --config Release --parallel 4 --verbose
if %errorlevel% neq 0 (
    echo [CRITICAL ERROR] Build Failed!
    pause
    exit /b 1
)

echo [SUCCESS] Build Completed Successfully!
if exist "Release\katago.exe" copy /Y "Release\katago.exe" "D:\ScytheKatago\katago.exe"
pause
