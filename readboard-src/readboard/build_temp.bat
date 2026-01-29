@echo off
cd /d D:\ScytheKatago\readboard-src\readboard
"C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" readboard.csproj /p:Configuration=Release /v:minimal
