@echo off
set LOG=D:\ScytheKatago\compile_log.txt
echo [STATUS] Starting Scythe-Katago Compilation... > %LOG% 2>&1

REM 1. Set up Visual Studio Environment
echo [Step 1] Setting up Environment... >> %LOG% 2>&1
set "PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Failed to set up VS environment. >> %LOG% 2>&1
    exit /b 1
)

REM Check CMake
cmake --version >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] CMake not found! >> %LOG% 2>&1
    exit /b 1
)

REM 2. Prepare Build Directory
echo [Step 2] Cleaning Build Directory...
if not exist "D:\ScytheKatago\KataGo\cpp\build" mkdir "D:\ScytheKatago\KataGo\cpp\build"
cd /d "D:\ScytheKatago\KataGo\cpp\build"

REM Clean old CMake cache
if exist "CMakeCache.txt" del "CMakeCache.txt"

REM 3. Configure CMake
echo [Step 3] Configuring CMake...
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib"
if %errorlevel% neq 0 (
    echo [ERROR] CMake configuration failed.
    exit /b 1
)

REM 4. Build Release Version
echo [Step 4] Building Katago...
cmake --build . --config Release --parallel 4 --verbose
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed.
    exit /b 1
)

REM 5. Deploy Executable
echo [Step 5] Deploying...
if exist "Release\katago.exe" (
    copy /Y "Release\katago.exe" "D:\ScytheKatago\katago.exe"
    echo [SUCCESS] Scythe-Katago is ready at D:\ScytheKatago\katago.exe
) else (
    echo [ERROR] Executable not found in Release folder!
)

