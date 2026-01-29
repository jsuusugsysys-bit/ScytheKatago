@echo off
echo [Step 1] Setting up Environment...
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

echo [Step 2] Cleaning Build Directory...
if exist "D:\ScytheKatago\KataGo\cpp\build\CMakeCache.txt" del "D:\ScytheKatago\KataGo\cpp\build\CMakeCache.txt"

if not exist "D:\ScytheKatago\KataGo\cpp\build" mkdir "D:\ScytheKatago\KataGo\cpp\build"
cd /d D:\ScytheKatago\KataGo\cpp\build

echo [Step 3] Configuring CMake...
echo Current Dir: %CD%
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib"

if %errorlevel% neq 0 (
    echo [ERROR] CMake Configuration Failed.
    exit /b 1
)

echo [Step 4] Building Executable...
cmake --build . --config Release --parallel 4 --verbose

if %errorlevel% neq 0 (
    echo [ERROR] Build Failed.
    exit /b 1
)

echo [SUCCESS] Build Complete.
if exist "Release\katago.exe" echo Found Executable at Release\katago.exe
