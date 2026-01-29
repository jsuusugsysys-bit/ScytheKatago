@echo off
set LOG=D:\ScytheKatago\rebuild_log.txt
echo STARTING REBUILD > %LOG% 2>&1

echo [1/5] Setting up Environment >> %LOG% 2>&1
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1

echo [2/5] Cleaning Build Directory >> %LOG% 2>&1
if exist "D:\ScytheKatago\KataGo\cpp\build" (
    rmdir /s /q "D:\ScytheKatago\KataGo\cpp\build" >> %LOG% 2>&1
)
mkdir "D:\ScytheKatago\KataGo\cpp\build" >> %LOG% 2>&1
cd /d "D:\ScytheKatago\KataGo\cpp\build" >> %LOG% 2>&1

echo [3/5] Configuring CMake >> %LOG% 2>&1
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib" >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] CMake Configure Failed >> %LOG% 2>&1
    exit /b 1
)

echo [4/5] Building Project >> %LOG% 2>&1
cmake --build . --config Release --parallel 4 --verbose >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Build Failed >> %LOG% 2>&1
    exit /b 1
)

echo [5/5] Checking Output >> %LOG% 2>&1
if exist "Release\katago.exe" (
    echo [SUCCESS] katago.exe found at Release\katago.exe >> %LOG% 2>&1
) else (
    echo [ERROR] katago.exe NOT found despite successful build code? >> %LOG% 2>&1
)
echo DONE >> %LOG% 2>&1
