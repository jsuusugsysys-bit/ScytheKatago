@echo off
set LOG=D:\ScytheKatago\compile_log.txt
echo [Step 1] Setting up Environment... > %LOG%
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1

echo [Step 2] Cleaning Build Directory... >> %LOG%
if exist "D:\ScytheKatago\KataGo\cpp\build\CMakeCache.txt" del "D:\ScytheKatago\KataGo\cpp\build\CMakeCache.txt"

cd /d D:\ScytheKatago\KataGo\cpp\build

echo [Step 3] Configuring CMake... >> %LOG%
echo Current Dir: %CD% >> %LOG%
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib" >> %LOG% 2>&1

if %errorlevel% neq 0 (
    echo [ERROR] CMake Configuration Failed. >> %LOG%
    exit /b 1
)

echo [Step 4] Building Executable... >> %LOG%
cmake --build . --config Release --parallel 4 --verbose >> %LOG% 2>&1

if %errorlevel% neq 0 (
    echo [ERROR] Build Failed. >> %LOG%
    exit /b 1
)

echo [SUCCESS] Build Complete. >> %LOG%
if exist "Release\katago.exe" echo Found Executable. >> %LOG%
