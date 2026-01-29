@echo off
set LOGFILE=D:\ScytheKatago\build_internal_log.txt
echo Starting Build... > %LOGFILE%
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOGFILE% 2>&1

if not exist "D:\ScytheKatago\KataGo\cpp\build" mkdir "D:\ScytheKatago\KataGo\cpp\build"
cd /d "D:\ScytheKatago\KataGo\cpp\build"

if exist CMakeCache.txt del CMakeCache.txt

echo Configuring CMake... >> %LOGFILE%
cmake .. -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="D:/ScytheKatago/eigen3" -DZLIB_INCLUDE_DIR="D:/ScytheKatago/zlib" -DZLIB_LIBRARY="D:/ScytheKatago/zlib/build/Release/zs.lib" >> %LOGFILE% 2>&1

echo Building... >> %LOGFILE%
cmake --build . --config Release --verbose >> %LOGFILE% 2>&1

