@echo off
cd /d D:\ScytheKatago
(
echo boardsize 11
echo clear_board
echo play b E5
echo play w F5
echo play b E6
echo play w F6
echo play b E7
echo play w F7
echo play b E8
echo play w F8
echo play b E9
echo play w F9
echo kata-get-scythe-status
echo kata-set-param scythe_trigger true
echo kata-get-scythe-status
echo quit
) | KataGo\cpp\build\Release\katago.exe gtp -model kata1-b6c96.bin.gz -config scythe_config.cfg
