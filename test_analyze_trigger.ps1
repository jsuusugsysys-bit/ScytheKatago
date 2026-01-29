$commands = Get-Content 'D:\ScytheKatago\test_analyze_scythe_trigger.txt' -Raw

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

Write-Host '=== Starting KataGo for kata-analyze with scythe trigger ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 2

Write-Host '=== Sending commands ===' -ForegroundColor Green
$p.StandardInput.Write($commands)
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(30000)

Write-Host ''
Write-Host '=== Analysis Output ===' -ForegroundColor Green
# Find the JSON output line
$lines = $stdout.Split("`n")
foreach ($line in $lines) {
    if ($line -match '^\s*=\s*$') {
        Write-Host $line
    } elseif ($line -match 'info\s+move') {
        Write-Host $line
        break
    } elseif ($line -match '{.*}') {
        Write-Host $line
    } elseif ($line.Trim().Length -gt 0) {
        Write-Host $line
    }
}

Write-Host ''
Write-Host '=== STDERR (last 20 lines) ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan
