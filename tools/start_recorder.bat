@echo off
chcp 65001 >nul
echo 启动野狐镰刀录屏工具...
echo.
python "%~dp0screen_recorder.py"
pause
