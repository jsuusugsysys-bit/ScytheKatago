$commands = Get-Content 'D:\ScytheKatago\test_analyze_final.txt' -Raw

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

Write-Host '=== Final kata-analyze test ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 2

$p.StandardInput.Write($commands)
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(60000)

Write-Host ''
Write-Host '=== Analysis JSON Output ===' -ForegroundColor Green
$lines = $stdout.Split("`n")
foreach ($line in $lines) {
    if ($line -match '^\s*{\s*"') {
        Write-Host $line -ForegroundColor Cyan
        # Try to parse and pretty print key fields
        if ($line -match '"move":\s*"([^"]+)"') {
            Write-Host "  Move: $($Matches[1])" -ForegroundColor Yellow
        }
        if ($line -match '"pv":\s*\[([^\]]+)\]') {
            Write-Host "  PV: $($Matches[1])" -ForegroundColor Yellow
        }
        if ($line -match '"pvPlayers":\s*\[([^\]]+)\]') {
            Write-Host "  PV Players: $($Matches[1])" -ForegroundColor Green
        }
    } elseif ($line -match '=\s*$|{"black|Scythe') {
        Write-Host $line
    }
}

Write-Host ''
Write-Host '=== STDERR (last 20 lines) ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan
