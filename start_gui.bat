@echo off
chcp 65001 >nul
title Lizzieyzy Scythe Edition

echo ========================================
echo   Lizzieyzy 镰刀版启动中...
echo ========================================

set JAVA_HOME=D:\ScytheKatago\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64
set PATH=%JAVA_HOME%\bin;%PATH%

cd /d D:\ScytheKatago\lizzieyzy-main\target

echo.
echo Java: %JAVA_HOME%
echo JAR: lizzie-yzy2.5.3-shaded.jar
echo.

"%JAVA_HOME%\bin\java.exe" -jar lizzie-yzy2.5.3-shaded.jar

if errorlevel 1 (
    echo.
    echo 启动失败！请检查 Java 路径。
    pause
)
