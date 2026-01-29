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
kata-analyze interval 100 maxmoves 5 ownership true
"@

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

Write-Host '=== 镰刀 PV 验证测试 ===' -ForegroundColor Cyan

$p.Start() | Out-Null

Start-Sleep -Seconds 3

$p.StandardInput.Write($commands)
$p.StandardInput.Flush()

Start-Sleep -Seconds 8

$p.StandardInput.Write("kata-analyze-stop`n")
$p.StandardInput.Flush()

Start-Sleep -Seconds 1

$p.StandardInput.Write("quit`n")
$p.StandardInput.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$p.WaitForExit(10000)

Write-Host ''
Write-Host '=== 分析输出（查找 pvPlayers） ===' -ForegroundColor Green

$lines = $stdout.Split("`n")
$foundPV = $false

foreach ($line in $lines) {
    if ($line -match 'pvPlayers') {
        Write-Host $line -ForegroundColor Cyan
        $foundPV = $true

        # 尝试解析 JSON
        if ($line -match '\{.*\}') {
            try {
                $json = $line | ConvertFrom-Json
                if ($json.moveInfos) {
                    foreach ($moveInfo in $json.moveInfos) {
                        if ($moveInfo.pvPlayers) {
                            $pvPlayers = $moveInfo.pvPlayers
                            Write-Host "  落子: $($moveInfo.move)" -ForegroundColor Yellow
                            Write-Host "  PV Players: $($pvPlayers -join ' ')" -ForegroundColor Yellow

                            if ($pvPlayers.Length -ge 2) {
                                if ($pvPlayers[0] -eq 'B' -and $pvPlayers[1] -eq 'B') {
                                    Write-Host "  ✅ SUCCESS: Scythe Active (B->B)" -ForegroundColor Green
                                } else {
                                    Write-Host "  ❌ FAIL: Normal Go Logic ($($pvPlayers[0])->$($pvPlayers[1]))" -ForegroundColor Red
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Host "  JSON 解析失败" -ForegroundColor Yellow
            }
        }
    }
}

if (-not $foundPV) {
    Write-Host "❌ 未找到 pvPlayers 字段" -ForegroundColor Red
    Write-Host ""
    Write-Host "完整输出（前100行）:" -ForegroundColor Yellow
    $lines | Select-Object -First 100 | ForEach-Object { Write-Host $_ }
}

Write-Host ''
Write-Host '=== STDERR（最后 20 行） ===' -ForegroundColor Yellow
$stderr.Split("`n") | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host "=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan
