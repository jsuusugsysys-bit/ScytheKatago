@echo off
chcp 65001 >nul
echo ========================================
echo 安装录屏工具依赖
echo ========================================
echo.

pip install opencv-python pyautogui pillow keyboard

echo.
echo ========================================
echo 安装完成！
echo ========================================
pause
