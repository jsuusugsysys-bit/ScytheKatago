$ErrorActionPreference = "Continue"
Set-Location "D:\ScytheKatago"

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

$process = New-Object System.Diagnostics.Process
$process.StartInfo.FileName = "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe"
$process.StartInfo.Arguments = "gtp -model D:\ScytheKatago\scythe11.bin.gz -config D:\ScytheKatago\scythe_config.cfg"
$process.StartInfo.UseShellExecute = $false
$process.StartInfo.RedirectStandardInput = $true
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardError = $true
$process.StartInfo.CreateNoWindow = $true

$process.Start() | Out-Null

$process.StandardInput.WriteLine($testInput)
$process.StandardInput.Close()

$output = $process.StandardOutput.ReadToEnd()
$errors = $process.StandardError.ReadToEnd()

$process.WaitForExit(60000)

Write-Host "=== STDOUT ===" -ForegroundColor Green
Write-Host $output

Write-Host "`n=== STDERR (last 50 lines) ===" -ForegroundColor Yellow
$errors.Split("`n") | Select-Object -Last 50 | ForEach-Object { Write-Host $_ }
