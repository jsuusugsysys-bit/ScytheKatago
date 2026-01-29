@echo off
cd /d D:\ScytheKatago

echo Testing katago version...
KataGo\cpp\build\Release\katago.exe version

echo.
echo Testing GTP...
echo quit | KataGo\cpp\build\Release\katago.exe gtp -model scythe11.bin.gz -config scythe_config.cfg

pause
