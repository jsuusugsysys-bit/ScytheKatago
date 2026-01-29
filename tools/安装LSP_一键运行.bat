@echo off
chcp 65001 >nul
echo ================================
echo    LSP 环境配置 - 一键运行
echo ================================
echo.
echo 此脚本将：
echo 1. 将 LLVM (clangd) 添加到系统 PATH
echo.
echo 需要管理员权限。
echo.
pause

echo.
echo 正在运行 PowerShell 脚本...
powershell -ExecutionPolicy Bypass -File "%~dp0add_llvm_to_path.ps1"

echo.
echo ================================
echo 完成！请关闭并重新打开终端。
echo ================================
pause
