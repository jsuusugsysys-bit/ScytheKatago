@echo off
echo ===== Compile gtp.cpp only =====

REM Find MSBuild
set MSBUILD="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
if not exist %MSBUILD% (
    echo ERROR: MSBuild not found!
    pause
    exit /b 1
)

REM Delete gtp.obj to force recompile
echo Deleting gtp.obj...
del /Q "D:\ScytheKatago\KataGo\cpp\build\gtp.dir\Release\gtp.obj" 2>nul

REM Build katago project only
echo Building KataGo...
cd /d "D:\ScytheKatago\KataGo\cpp\build"
%MSBUILD% katago.vcxproj /p:Configuration=Release /m /v:minimal

if %errorlevel% neq 0 (
    echo BUILD FAILED
    pause
    exit /b 1
)

echo.
echo BUILD SUCCESS!
dir /TC Release\katago.exe
echo.
pause
