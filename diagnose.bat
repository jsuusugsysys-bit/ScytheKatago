@echo off
set LOG=D:\ScytheKatago\full_build_log.txt
echo STARTING DIAGNOSIS > %LOG%

echo 1. Setting up Environment >> %LOG%
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1
if %errorlevel% neq 0 echo VCVARS FAILED >> %LOG%

echo 2. Setting Path for CMake >> %LOG%
set "PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
cmake --version >> %LOG% 2>&1

echo 3. Checking Directories >> %LOG%
if not exist "D:\ScytheKatago\KataGo\cpp\build" mkdir "D:\ScytheKatago\KataGo\cpp\build"
cd /d "D:\ScytheKatago\KataGo\cpp\build"

echo 4. Cleaning Cache >> %LOG%
if exist CMakeCache.txt del CMakeCache.txt

echo 5. Configuring CMake >> %LOG%
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib" >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo CMAKE CONFIGURATION FAILED >> %LOG%
    exit /b 1
)

echo 6. Building >> %LOG%
cmake --build . --config Release --parallel 4 >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo BUILD FAILED >> %LOG%
    exit /b 1
)

echo BUILD SUCCESS >> %LOG%
