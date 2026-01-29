@echo off
echo ===== Compiling KataGo =====

REM Setup VS environment
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

REM Clean search.obj to force recompile
echo Cleaning search.obj...
if exist "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\search.obj" (
    del "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\search.obj"
    echo Deleted search.obj
)

REM Build
echo Building...
cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4

if %errorlevel% neq 0 (
    echo BUILD FAILED
    exit /b 1
)

echo BUILD SUCCESS
dir Release\katago.exe

REM Copy to scythe_lizzie
copy /Y "Release\katago.exe" "D:\ScytheKatago\scythe_lizzie\katago.exe"
echo Done!
