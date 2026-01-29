$commands = Get-Content 'D:\ScytheKatago\test_analyze_final.txt' -Raw

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = 'D:\ScytheKatago\ScytheEngine\katago.exe'
$pinfo.Arguments = 'gtp -model D:\ScytheKatago\ScytheEngine\scythe11.bin.gz -config D:\ScytheKatago\ScytheEngine\scythe_config.cfg'
$pinfo.RedirectStandardInput = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.WorkingDirectory = 'D:\ScytheKatago\ScytheEngine'

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo

Write-Host '=== 镰刀 PV 验证测试（ScytheEngine） ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 2

$p.StandardInput.Write($commands)
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(60000)

Write-Host ''
Write-Host '=== JSON 输出（含 pvPlayers） ===' -ForegroundColor Green

$lines = $stdout.Split("`n")
$foundPV = $false
$testResult = "UNKNOWN"

foreach ($line in $lines) {
    if ($line -match '^\s*{\s*"') {
        Write-Host $line -ForegroundColor Cyan

        # 检查 pvPlayers
        if ($line -match '"pvPlayers":\s*\[([^\]]+)\]') {
            $pvPlayersStr = $Matches[1]
            Write-Host "  PV Players: $pvPlayersStr" -ForegroundColor Yellow
            $foundPV = $true

            # 解析前两个玩家
            if ($pvPlayersStr -match '"([BW])".*"([BW])"') {
                $player1 = $Matches[1]
                $player2 = $Matches[2]

                if ($player1 -eq 'B' -and $player2 -eq 'B') {
                    Write-Host "  ✅ SUCCESS: Scythe Active (B->B)" -ForegroundColor Green
                    $testResult = "PASS"
                } else {
                    Write-Host "  ❌ FAIL: Normal Go Logic ($player1->$player2)" -ForegroundColor Red
                    $testResult = "FAIL"
                }
            }
        }

        if ($line -match '"move":\s*"([^"]+)"') {
            Write-Host "  Move: $($Matches[1])" -ForegroundColor Yellow
        }
        if ($line -match '"pv":\s*\[([^\]]+)\]') {
            $pvStr = $Matches[1]
            Write-Host "  PV: $($pvStr.Substring(0, [Math]::Min(80, $pvStr.Length)))" -ForegroundColor Yellow
        }
    } elseif ($line -match 'blackScythes|scytheCombo') {
        Write-Host $line -ForegroundColor Magenta
    }
}

if (-not $foundPV) {
    Write-Host ""
    Write-Host "❌ 未找到 pvPlayers 字段!" -ForegroundColor Red
    Write-Host "完整输出:" -ForegroundColor Yellow
    $lines | Select-Object -First 50 | ForEach-Object { Write-Host $_ }
}

Write-Host ''
Write-Host '=== STDERR（最后 30 行） ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 30 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== 测试结果: $testResult ===" -ForegroundColor Cyan
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan

if ($testResult -eq "PASS") {
    exit 0
} else {
    exit 1
}
