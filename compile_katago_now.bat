@echo off
echo ===== 编译 KataGo 引擎 =====
cd /d D:\ScytheKatago\KataGo\cpp\build

echo.
echo [1/2] 使用 CMake 编译...
cmake --build . --config Release --parallel 4

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo CMake 编译失败，尝试 MSBuild...
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" katago.sln /p:Configuration=Release /m
)

echo.
echo ===== 编译完成 =====
dir /TC Release\katago.exe

pause
