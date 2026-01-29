$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe"
$pinfo.Arguments = "gtp -model D:\ScytheKatago\scythe11.bin.gz -config D:\ScytheKatago\scythe_config.cfg"
$pinfo.RedirectStandardInput = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.WorkingDirectory = "D:\ScytheKatago"

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo

try {
    Write-Host "=== Starting KataGo GTP ===" -ForegroundColor Cyan

    $p.Start() | Out-Null

    # 异步读取 stderr（调试输出）
    $stderrJob = Start-Job -ScriptBlock {
        param($stream)
        $stream.ReadToEnd()
    } -ArgumentList $p.StandardError

    # 等待 GTP ready
    Start-Sleep -Seconds 3

    # 发送命令并读取响应
    $commands = @(
        "boardsize 11",
        "clear_board",
        "play B F6",
        "play W G6",
        "play B F7",
        "play W G7",
        "play B F8",
        "play W G8",
        "play B F5",
        "play W G5",
        "play B F4",
        "play W G4",
        "play B E6",
        "kata-get-scythe-status",
        "kata-scythe-genmove B",
        "quit"
    )

    Write-Host "`n=== Sending GTP Commands ===" -ForegroundColor Green

    foreach ($cmd in $commands) {
        Write-Host "> $cmd" -ForegroundColor Cyan
        $p.StandardInput.WriteLine($cmd)
        $p.StandardInput.Flush()

        # 读取响应
        Start-Sleep -Milliseconds 500

        while ($p.StandardOutput.Peek() -ge 0) {
            $line = $p.StandardOutput.ReadLine()
            Write-Host "  $line"

            # 如果遇到空行，说明响应结束
            if ([string]::IsNullOrWhiteSpace($line)) {
                break
            }
        }
    }

    $p.WaitForExit(10000)

    # 获取 stderr
    $stderr = Receive-Job -Job $stderrJob

    Write-Host "`n=== STDERR (init messages) ===" -ForegroundColor Yellow
    $stderr.Split("`n") | Select-Object -First 20 | ForEach-Object { Write-Host $_ }

    Write-Host "`n=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($stderrJob) {
        Stop-Job -Job $stderrJob -ErrorAction SilentlyContinue
        Remove-Job -Job $stderrJob -ErrorAction SilentlyContinue
    }
}
