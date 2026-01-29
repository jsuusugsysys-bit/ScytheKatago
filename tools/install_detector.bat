@echo off
chcp 65001 >nul
echo ========================================
echo 安装镰刀识别测试工具依赖
echo ========================================
echo.
echo 这可能需要几分钟，请耐心等待...
echo.

pip install opencv-python pyautogui pillow easyocr

echo.
echo ========================================
echo 安装完成！
echo ========================================
pause
