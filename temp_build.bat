@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4
echo BUILD_EXIT_CODE=%errorlevel%
