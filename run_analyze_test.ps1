# Run KataGo with test input and capture output
$katago = "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe"
$model = "D:\ScytheKatago\kata1-b6c96.bin.gz"
$config = "D:\ScytheKatago\scythe_config.cfg"
$input = "D:\ScytheKatago\test_analyze_after_move12.txt"

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $katago
$pinfo.Arguments = "gtp -model $model -config $config"
$pinfo.RedirectStandardInput = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null

# Send input
$input_content = Get-Content $input -Raw
$p.StandardInput.Write($input_content)
$p.StandardInput.Close()

# Wait for some output
Start-Sleep -Seconds 15
try { $p.Kill() } catch {}

Write-Host "=== STDOUT ==="
$stdout = $p.StandardOutput.ReadToEnd()
Write-Host $stdout

Write-Host "`n=== STDERR ==="
$stderr = $p.StandardError.ReadToEnd()
Write-Host $stderr
