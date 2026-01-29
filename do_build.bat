@echo off
echo Starting compilation...
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d D:\ScytheKatago\KataGo\cpp\build
cmake --build . --config Release 2>&1
echo Done. Exit code: %errorlevel%
