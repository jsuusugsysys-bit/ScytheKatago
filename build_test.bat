@echo off
chcp 65001 >nul
echo Building KataGo...
cd /d "D:\ScytheKatago\KataGo\cpp\build"
"C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" katago.sln /p:Configuration=Release /m
echo.
echo Build completed with error level: %errorlevel%
