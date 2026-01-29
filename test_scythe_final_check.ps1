$commands = @"
boardsize 11
clear_board
play B F6
play W G6
play B F7
play W G7
kata-set-param scythe_trigger_player black
kata-set-param scythe_trigger true
kata-get-scythe-status
kata-analyze interval 100 ownership true maxmoves 5
"@

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = 'D:\ScytheKatago\ScytheEngine\katago.exe'
$pinfo.Arguments = 'gtp -model scythe11.bin.gz -config scythe_config.cfg'
$pinfo.RedirectStandardInput = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.WorkingDirectory = 'D:\ScytheKatago\ScytheEngine'

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo

Write-Host '=== Scythe PV Test ===' -ForegroundColor Cyan

$p.Start() | Out-Null
Start-Sleep -Seconds 2

$p.StandardInput.WriteLine($commands)
$p.StandardInput.Flush()

# Wait for analysis
Start-Sleep -Seconds 6

$p.StandardInput.WriteLine("kata-analyze-stop")
$p.StandardInput.Flush()
Start-Sleep -Seconds 1

$p.StandardInput.WriteLine("quit")
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$p.WaitForExit(10000)

Write-Host ''
Write-Host '=== JSON Output ===' -ForegroundColor Green

$lines = $stdout.Split("`n")
$testResult = "UNKNOWN"

foreach ($line in $lines) {
    if ($line -match '^\s*\{.*"moveInfos"') {
        Write-Host $line.Substring(0, [Math]::Min(500, $line.Length)) -ForegroundColor Cyan

        if ($line -match '"pvPlayers":\s*\[([^\]]+)\]') {
            $pvPlayersStr = $Matches[1]
            Write-Host "Found pvPlayers: $pvPlayersStr" -ForegroundColor Yellow

            if ($pvPlayersStr -match '"B"[^"]*"B"') {
                Write-Host "SUCCESS: B->B found!" -ForegroundColor Green
                $testResult = "PASS"
            } elseif ($pvPlayersStr -match '"B"[^"]*"W"') {
                Write-Host "FAIL: B->W found!" -ForegroundColor Red
                $testResult = "FAIL"
            }
        }
    }
}

if ($testResult -eq "UNKNOWN") {
    Write-Host "No pvPlayers found" -ForegroundColor Red
    Write-Host "First 50 lines:" -ForegroundColor Yellow
    $lines | Select-Object -First 50 | ForEach-Object { Write-Host $_ }
}

Write-Host ''
Write-Host "=== Result: $testResult ===" -ForegroundColor Cyan
