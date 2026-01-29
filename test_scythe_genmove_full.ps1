$testInput = @"
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
"@

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

    # 发送命令
    $p.StandardInput.Write($testInput)
    $p.StandardInput.Close()

    # 等待输出
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    $p.WaitForExit(60000)

    Write-Host "`n=== GTP OUTPUT ===" -ForegroundColor Green
    Write-Host $stdout

    if ($stderr) {
        Write-Host "`n=== STDERR (last 30 lines) ===" -ForegroundColor Yellow
        $stderr.Split("`n") | Select-Object -Last 30 | ForEach-Object { Write-Host $_ }
    }

    Write-Host "`n=== Exit Code: $($p.ExitCode) ===" -ForegroundColor Cyan

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
