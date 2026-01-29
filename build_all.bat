@echo off
chcp 65001 >nul
title 镰刀项目编译工具

echo ========================================
echo    镰刀项目统一编译工具
echo ========================================
echo.
echo 请选择要编译的组件:
echo.
echo   1. readboard  - C# 棋盘同步工具
echo   2. lizzie     - Java GUI
echo   3. katago     - C++ 引擎
echo   4. all        - 编译所有
echo   5. 退出
echo.

set /p choice=请输入选项 (1-5):

if "%choice%"=="1" goto build_readboard
if "%choice%"=="2" goto build_lizzie
if "%choice%"=="3" goto build_katago
if "%choice%"=="4" goto build_all
if "%choice%"=="5" exit /b 0
goto invalid

:build_readboard
echo.
echo [编译 readboard...]
"C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\ScytheKatago\readboard-src\readboard\readboard.csproj" /p:Configuration=Release /t:Build /v:minimal
if %errorlevel% neq 0 (
    echo [错误] readboard 编译失败！
    pause
    exit /b 1
)
echo [复制到部署目录...]
copy /y "D:\ScytheKatago\readboard-src\readboard\bin\Release\readboard.exe" "D:\ScytheKatago\scythe_lizzie\readboard\readboard.exe"
echo [完成] readboard 编译成功！
goto done

:build_lizzie
echo.
echo [编译 lizzieyzy...]
cd /d "D:\ScytheKatago\lizzieyzy-main"
call mvn package -DskipTests
if %errorlevel% neq 0 (
    echo [错误] lizzieyzy 编译失败！
    pause
    exit /b 1
)
echo [完成] lizzieyzy 编译成功！
goto done

:build_katago
echo.
echo [编译 KataGo...]
cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4
if %errorlevel% neq 0 (
    echo [错误] KataGo 编译失败！
    pause
    exit /b 1
)
echo [完成] KataGo 编译成功！
goto done

:build_all
call :build_readboard
call :build_lizzie
call :build_katago
echo.
echo ========================================
echo    所有组件编译完成！
echo ========================================
goto done

:invalid
echo 无效选项，请重新运行。
pause
exit /b 1

:done
echo.
pause
