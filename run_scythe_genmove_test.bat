@echo off
chcp 65001 >nul
cd /d D:\ScytheKatago

echo === 测试 kata-scythe-genmove 命令 ===
echo.

type test_scythe_genmove.txt | KataGo\cpp\build\Release\katago.exe gtp -model kata1-b6c96.bin.gz -config scythe_config.cfg

echo.
echo === 测试完成 ===
pause
