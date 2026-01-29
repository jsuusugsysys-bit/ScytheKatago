@echo off
set LOG=D:\ScytheKatago\last_build.log
echo [START] > %LOG%

call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1

cd /d "D:\ScytheKatago\KataGo\cpp\build"
if exist CMakeCache.txt del CMakeCache.txt

echo [CONFIGURING] >> %LOG%
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib" >> %LOG% 2>&1

if %errorlevel% neq 0 (
    echo [CONFIG FAILED] >> %LOG%
    exit /b 1
)

echo [BUILDING] >> %LOG%
cmake --build . --config Release --parallel 4 >> %LOG% 2>&1

if %errorlevel% neq 0 (
    echo [BUILD FAILED] >> %LOG%
    exit /b 1
)

echo [SUCCESS] >> %LOG%
if exist "Release\katago.exe" copy /Y "Release\katago.exe" "D:\ScytheKatago\katago.exe" >> %LOG% 2>&1
