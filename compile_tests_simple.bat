@echo off
echo ===== Compile KataGo Tests =====

REM Use MSBuild directly
set MSBUILD=C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe

if not exist "%MSBUILD%" (
    echo ERROR: MSBuild not found at %MSBUILD%
    pause
    exit /b 1
)

echo Found MSBuild
echo.

REM Clean test object files to force recompile
echo Cleaning object files...
cd /d "D:\ScytheKatago\KataGo\cpp\build"

if exist "tests.dir\Release\testscythe.obj" (
    del "tests.dir\Release\testscythe.obj"
    echo Deleted testscythe.obj
)
if exist "tests.dir\Release\runtests.obj" (
    del "tests.dir\Release\runtests.obj"
    echo Deleted runtests.obj
)
if exist "katago.dir\Release\boardhistory.obj" (
    del "katago.dir\Release\boardhistory.obj"
    echo Deleted boardhistory.obj
)

echo.
echo Building KataGo...
"%MSBUILD%" katago.sln /p:Configuration=Release /m /v:minimal

if %errorlevel% neq 0 (
    echo.
    echo ===== BUILD FAILED =====
    pause
    exit /b 1
)

echo.
echo ===== BUILD SUCCESS =====
dir /TC Release\katago.exe 2>nul
echo.
echo Done!
