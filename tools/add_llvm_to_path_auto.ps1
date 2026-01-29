# 永久添加 LLVM 到系统 PATH（自动化版本）

$llvmPath = "C:\Program Files\LLVM\bin"

# 检查路径是否存在
if (Test-Path $llvmPath) {
    Write-Host "找到 LLVM: $llvmPath" -ForegroundColor Green

    # 获取当前用户的 PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    # 检查是否已经在 PATH 中
    if ($currentPath -like "*$llvmPath*") {
        Write-Host "LLVM 已经在 PATH 中" -ForegroundColor Yellow
        exit 0
    } else {
        # 添加到 PATH
        $newPath = $currentPath + ";" + $llvmPath
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "成功添加 LLVM 到 PATH！" -ForegroundColor Green
        Write-Host "已生效（当前用户）" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "错误：找不到 LLVM 安装目录" -ForegroundColor Red
    Write-Host "预期位置：$llvmPath" -ForegroundColor Red
    exit 1
}
