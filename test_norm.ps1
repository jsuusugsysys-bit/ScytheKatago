$commands = Get-Content 'D:\ScytheKatago\test_norm_analyze.txt' -Raw

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

Write-Host '=== Normal analyze test (no scythe) ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 2

$p.StandardInput.Write($commands)
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(60000)

Write-Host ''
Write-Host '=== First 80 lines of output ===' -ForegroundColor Green
$stdout.Split("`n") | Select-Object -First 80 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host '=== STDERR (last 15 lines) ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 15 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan
