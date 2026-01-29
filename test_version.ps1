$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe"
$pinfo.Arguments = "version"
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.WorkingDirectory = "D:\ScytheKatago\KataGo\cpp\build\Release"

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo

try {
    $started = $p.Start()

    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit(10000)

    Write-Host "=== STDOUT ==="
    Write-Host $stdout

    if ($stderr) {
        Write-Host "`n=== STDERR ==="
        Write-Host $stderr
    }

    Write-Host "`n=== Exit Code: $($p.ExitCode) ==="

    if ($p.ExitCode -eq 0) {
        Write-Host "SUCCESS!" -ForegroundColor Green
    } else {
        Write-Host "FAILED with code: $($p.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
