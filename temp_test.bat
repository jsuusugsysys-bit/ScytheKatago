@echo off
chcp 65001
D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe gtp -model "D:\2025-05-19-win64-RTX50XX特供版\weights\28b.bin.gz" -config D:\ScytheKatago\scythe_config.cfg < D:\ScytheKatago\quick_test_fix.txt
