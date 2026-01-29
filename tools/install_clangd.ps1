# Clangd 自动安装脚本（通过 LLVM）

Write-Host "=== Clangd 安装脚本 ===" -ForegroundColor Green
Write-Host "`n方法 1：使用 winget（推荐，最简单）" -ForegroundColor Yellow
Write-Host "运行命令：winget install LLVM.LLVM" -ForegroundColor Cyan
Write-Host ""

Write-Host "方法 2：手动下载 LLVM" -ForegroundColor Yellow
Write-Host "1. 访问：https://github.com/llvm/llvm-project/releases" -ForegroundColor Cyan
Write-Host "2. 下载最新的 LLVM-*-win64.exe 安装包" -ForegroundColor Cyan
Write-Host "3. 运行安装程序，勾选 'Add LLVM to system PATH'" -ForegroundColor Cyan
Write-Host ""

Write-Host "检查 winget 是否可用..." -ForegroundColor Green
$wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue

if ($wingetAvailable) {
    Write-Host "✅ winget 可用！" -ForegroundColor Green
    $response = Read-Host "`n是否现在使用 winget 安装 LLVM？（包含 clangd）[Y/N]"

    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host "`n开始安装 LLVM（包含 clangd）..." -ForegroundColor Green
        winget install LLVM.LLVM

        Write-Host "`n安装完成！请重新打开终端，然后运行 'clangd --version' 验证。" -ForegroundColor Green
    } else {
        Write-Host "已取消安装。" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ winget 不可用（需要 Windows 10 1809+ 或 Windows 11）" -ForegroundColor Red
    Write-Host "请使用方法 2 手动下载安装。" -ForegroundColor Yellow
}
