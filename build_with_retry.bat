@echo off
chcp 65001 >nul
title 镰刀项目编译工具 (带重试管理)

echo ========================================
echo    镰刀项目编译工具 (带重试管理)
echo ========================================
echo.
echo 核心原则：
echo - 最多重试 1 次（总共尝试 2 次）
echo - 失败后不再盲目重试
echo - 详细的日志记录
echo.
echo ========================================
echo.

REM 检查 Python 是否可用
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 找不到 Python，请先安装 Python 3.7+
    echo.
    echo 如果已安装，请确保 Python 在 PATH 环境变量中
    pause
    exit /b 1
)

REM 执行 Python 编译脚本
python "%~dp0tools\compile_with_retry.py"

REM 检查结果
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo    编译失败
    echo ========================================
    echo.
    echo 请查看日志文件了解详情：
    echo D:\ScytheKatago\compile_retry.log
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo    编译成功！
echo ========================================
echo.
pause
exit /b 0
