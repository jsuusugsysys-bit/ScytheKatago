@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if not exist "D:\ScytheKatago\KataGo\cpp\build" mkdir "D:\ScytheKatago\KataGo\cpp\build"
cd /d D:\ScytheKatago\KataGo\cpp\build

echo Configuring CMake...
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib"
if %errorlevel% neq 0 (
    echo CMake Configuration Failed
    exit /b 1
)

echo Building...
cmake --build . --config Release --parallel 4
if %errorlevel% neq 0 (
    echo Build Failed
    exit /b 1
)

echo Build Success
