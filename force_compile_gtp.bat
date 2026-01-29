@echo off
echo === Force recompile GTP ===

REM Delete all gtp-related object files
del /Q "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\gtp.obj" 2>nul
del /Q "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\boardhistory.obj" 2>nul
del /Q "D:\ScytheKatago\KataGo\cpp\build\katago.dir\Release\asyncbot.obj" 2>nul

echo Deleted object files

REM Setup VS environment
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

REM Build
cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4

echo.
echo Copying to scythe_lizzie...
copy /Y "Release\katago.exe" "D:\ScytheKatago\scythe_lizzie\katago.exe"

echo.
echo Done!
pause
