$katago = "D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe"
$model = "D:\2025-05-19-win64-RTX50XX特供版\weights\28b.bin.gz"
$config = "D:\ScytheKatago\scythe_config.cfg"
$input = "D:\ScytheKatago\quick_test.txt"

Write-Host "Starting KataGo test..."
Write-Host "KataGo: $katago"
Write-Host "Model: $model"
Write-Host "Config: $config"
Write-Host ""

& $katago gtp -model $model -config $config | Out-Null
Get-Content $input | & $katago gtp -model $model -config $config
