@echo off
chcp 65001 >nul
echo ========================================
echo Testing KataGo Analysis Fix
echo ========================================
echo.

cd /d D:\ScytheKatago

echo Test: Move 12 analysis on 11x11 board
echo.

D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe gtp -model kata1-b6c96.bin.gz -config scythe_config.cfg < test_analyze_after_move12.txt

echo.
echo ========================================
echo Test completed
echo ========================================
pause
