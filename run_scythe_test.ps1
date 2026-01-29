$ErrorActionPreference = "Continue"
Set-Location "D:\ScytheKatago"

Write-Host "=== Testing kata-scythe-genmove ===" -ForegroundColor Green

$testInput = @"
boardsize 11
clear_board
play B F6
play W G6
play B F7
play W G7
play B F8
play W G8
play B F5
play W G5
play B F4
play W G4
play B E6
kata-get-scythe-status
kata-scythe-genmove B
quit
"@

$testInput | & "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe" gtp -model "D:\ScytheKatago\kata1-b6c96.bin.gz" -config "D:\ScytheKatago\scythe_config.cfg" 2>&1

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
