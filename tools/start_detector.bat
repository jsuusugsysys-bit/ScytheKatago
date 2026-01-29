@echo off
chcp 65001 >nul
echo 启动野狐镰刀识别测试工具...
echo.
python "%~dp0scythe_detector_test.py"
pause
