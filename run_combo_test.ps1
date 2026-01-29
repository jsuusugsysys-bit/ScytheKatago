$testInput = @"
boardsize 11
clear_board
play b E5
play w F5
play b E6
play w F6
play b E7
play w F7
play b E8
play w F8
play b E9
play w F9
kata-get-scythe-status
kata-set-param scythe_trigger true
kata-get-scythe-status
quit
"@

$testInput | & "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe" gtp -model "D:\ScytheKatago\kata1-b6c96.bin.gz" -config "D:\ScytheKatago\scythe_config.cfg"
