@echo off
set "PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
echo Starting Full Build Process...

REM --- Step 1: Check and Compile ZLIB ---
if not exist "D:\ScytheKatago\zlib" (
    echo [Error] ZLIB folder not found!
    echo Please download zlib manually if the automatic download failed.
    echo Expected path: D:\ScytheKatago\zlib
    exit /b
)

echo [Step 1/2] Compiling ZLIB...
cd /d "D:\ScytheKatago\zlib"
if not exist "build" mkdir "build"
cd "build"
REM Clean cache
if exist "CMakeCache.txt" del /q "CMakeCache.txt"

REM Configure ZLIB
cmake .. -Dbs_BUILD_ZLIB_AS_LIB=ON
if %errorlevel% neq 0 (
    echo [Error] ZLIB Configuration failed.
    exit /b
)

REM Build ZLIB
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo [Error] ZLIB Build failed.
    exit /b
)
echo ZLIB built successfully!

REM --- Step 2: Compile Katago ---
echo [Step 2/2] Compiling Katago...
cd /d "D:\ScytheKatago\KataGo"
if not exist "cpp\build" mkdir "cpp\build"
cd "cpp\build"

REM Clean cache to ensure new settings apply
if exist "CMakeCache.txt" del /q "CMakeCache.txt"
if exist "CMakeFiles" rmdir /s /q "CMakeFiles"

echo Configuring Katago with Eigen and local ZLIB...
cmake .. -DUSE_BACKEND=EIGEN ^
 -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" ^
 -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" ^
 -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib"

if %errorlevel% neq 0 (
    echo [Error] Katago Configuration failed.
    pause
    exit /b
)

echo Compiling Katago...
cmake --build . --config Release --parallel 4

if %errorlevel% neq 0 (
    echo [Error] Katago Build failed.
    pause
    exit /b
)

echo ---------------------------------------------------
echo Build process finished!
echo Your Scythe-Katago is ready at:
echo D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe
echo ---------------------------------------------------
pause
