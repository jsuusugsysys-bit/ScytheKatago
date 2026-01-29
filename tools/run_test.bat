@echo off
chcp 65001 >nul
echo ========================================
echo 运行内部自测
echo ========================================
echo.

REM 先安装依赖
pip install opencv-python pyautogui pillow pygetwindow numpy --quiet

echo.
echo 开始自测...
echo.

python "%~dp0scythe_auto.py" --test

echo.
pause
