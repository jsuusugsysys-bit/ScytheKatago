@echo off
cd /d "D:\ScytheKatago"
echo === Running GTP Test ===
"D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe" gtp -model scythe11.bin.gz -config scythe_config.cfg < test_beginsearch.txt
echo.
echo === Test Complete ===
