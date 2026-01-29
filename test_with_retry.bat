@echo off
chcp 65001 >nul
title 镰刀测试套件 (带重试管理)

echo ========================================
echo    镰刀测试套件 (带重试管理)
echo ========================================
echo.

REM 检查 Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 找不到 Python
    pause
    exit /b 1
)

REM 运行测试
python "%~dp0tools\run_tests_with_retry.py"

if %errorlevel% neq 0 (
    echo.
    echo [失败] 有测试未通过
    pause
    exit /b 1
)

echo.
pause
exit /b 0
