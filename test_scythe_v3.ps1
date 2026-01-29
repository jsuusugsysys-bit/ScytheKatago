$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = 'D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe'
$pinfo.Arguments = 'gtp -model D:\ScytheKatago\scythe11.bin.gz -config D:\ScytheKatago\scythe_config.cfg'
$pinfo.RedirectStandardInput = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.WorkingDirectory = 'D:\ScytheKatago'

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo

Write-Host '=== Starting KataGo GTP ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 2

$commands = @'
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
'@

Write-Host ''
Write-Host '=== Sending Commands ===' -ForegroundColor Green
$p.StandardInput.Write($commands)
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(30000)

Write-Host ''
Write-Host '=== GTP STDOUT ===' -ForegroundColor Green
Write-Host $stdout

Write-Host ''
Write-Host '=== STDERR (last 20 lines) ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan
