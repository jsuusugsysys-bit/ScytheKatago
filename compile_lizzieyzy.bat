@echo off
echo ========================================
echo 编译 Lizzieyzy (镰刀修复版)
echo ========================================
echo.

cd /d "d:\ScytheKatago\lizzieyzy-main"

echo [1/2] 清理旧的编译文件...
call mvn clean

echo.
echo [2/2] 编译新版本...
call mvn package -DskipTests

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo ✅ 编译成功！
    echo ========================================
    echo.
    echo 输出文件：target\lizzie-yzy2.5.3-shaded.jar
    echo.
    echo 运行命令：
    echo cd /d d:\ScytheKatago\lizzieyzy-main\target
    echo java -jar lizzie-yzy2.5.3-shaded.jar
    echo.
) else (
    echo.
    echo ========================================
    echo ❌ 编译失败！
    echo ========================================
    echo 请检查错误信息
)

pause
