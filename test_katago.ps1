$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe"
$pinfo.Arguments = "version"
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo

try {
    $started = $p.Start()
    Write-Host "Process started: $started"

    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit(10000)

    Write-Host "=== STDOUT ==="
    Write-Host $stdout
    Write-Host "=== STDERR ==="
    Write-Host $stderr
    Write-Host "=== Exit Code: $($p.ExitCode) ==="
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
