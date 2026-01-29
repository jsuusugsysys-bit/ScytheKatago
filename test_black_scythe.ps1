$commands = Get-Content 'D:\ScytheKatago\test_analyze_black_scythe.txt' -Raw

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

Write-Host '=== Testing kata-analyze with BLACK scythe ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 2

$p.StandardInput.Write($commands)
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(30000)

Write-Host ''
Write-Host '=== GTP Output (first 30 lines) ===' -ForegroundColor Green
$stdout.Split("`n") | Select-Object -First 30 | ForEach-Object {
    if ($_ -match 'info\s+move|pv|pvPlayers') {
        Write-Host $_ -ForegroundColor Yellow
    } else {
        Write-Host $_
    }
}

Write-Host ''
Write-Host '=== STDERR (last 20 lines) ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan
