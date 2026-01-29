# JDTLS 自动安装脚本

$jdtlsDir = "D:\ScytheKatago\tools\jdtls"
$downloadUrl = "https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.40.0/jdt-language-server-1.40.0-202409261450.tar.gz&mirror_id=1"
$tarFile = "$jdtlsDir\jdtls.tar.gz"

Write-Host "开始下载 Eclipse JDT Language Server..." -ForegroundColor Green

# 下载
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tarFile -UseBasicParsing
    Write-Host "下载完成！" -ForegroundColor Green
} catch {
    Write-Host "下载失败：$_" -ForegroundColor Red
    Write-Host "`n请手动下载：" -ForegroundColor Yellow
    Write-Host "https://download.eclipse.org/jdtls/milestones/" -ForegroundColor Cyan
    exit 1
}

# 解压（需要 tar 命令，Windows 10+ 自带）
Write-Host "正在解压..." -ForegroundColor Green
tar -xzf $tarFile -C $jdtlsDir
Remove-Item $tarFile

Write-Host "`n安装完成！" -ForegroundColor Green
Write-Host "jdtls 位置：$jdtlsDir" -ForegroundColor Cyan
Write-Host "`n下一步：在 Claude Code 中运行 '/plugin install jdtls-lsp@claude-plugins-official'" -ForegroundColor Yellow
