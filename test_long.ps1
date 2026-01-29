$commands = Get-Content 'D:\ScytheKatago\test_analyze_long.txt' -Raw

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

Write-Host '=== Testing kata-analyze with maxVisits ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 2

$p.StandardInput.Write($commands)
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(60000)

Write-Host ''
Write-Host '=== Analysis Output ===' -ForegroundColor Green
# Extract JSON lines
$lines = $stdout.Split("`n")
$foundInfo = $false
foreach ($line in $lines) {
    if ($line -match 'info\s+move') {
        Write-Host $line -ForegroundColor Yellow
        $foundInfo = $true
    } elseif ($line -match '{.*"move".*}') {
        Write-Host $line -ForegroundColor Cyan
    } elseif ($line.Trim() -eq '=') {
        Write-Host $line
    }
}

if (-not $foundInfo) {
    Write-Host "NO analysis output found!" -ForegroundColor Red
    Write-Host "Full stdout (first 50 lines):" -ForegroundColor Red
    $lines | Select-Object -First 50 | ForEach-Object { Write-Host $_ }
}

Write-Host ''
Write-Host '=== STDERR (last 30 lines) ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 30 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan
