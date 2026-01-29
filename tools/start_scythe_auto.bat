@echo off
chcp 65001 >nul
echo ========================================
echo 野狐镰刀自动触发工具
echo ========================================
echo.
echo 使用前请确保：
echo 1. lizzieyzy 已启动（连接 KataGo 镰刀版）
echo 2. readboard 已启动（棋盘同步工具）
echo 3. 模板图片已放入 templates 文件夹
echo.
echo ========================================
echo.
python "%~dp0scythe_auto.py"
pause
