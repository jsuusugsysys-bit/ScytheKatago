@echo off
REM 使用 WinSCP 命令行自动下载
REM 创建时间: 2026-01-24
REM 优点: 完全自动化,无需手动输入密码

echo ========================================
echo WinSCP 自动下载（无人值守版）
echo ========================================
echo.
echo 本脚本使用 WinSCP 命令行版本 (winscp.com) 自动下载
echo 优点: 自动输入密码,完全无人值守
echo.

REM 查找 WinSCP.com 路径
set WINSCP_PATH=

REM 常见安装路径
if exist "C:\Program Files\WinSCP\WinSCP.com" (
    set WINSCP_PATH=C:\Program Files\WinSCP\WinSCP.com
) else if exist "C:\Program Files (x86)\WinSCP\WinSCP.com" (
    set WINSCP_PATH=C:\Program Files (x86)\WinSCP\WinSCP.com
) else if exist "%ProgramFiles%\WinSCP\WinSCP.com" (
    set WINSCP_PATH=%ProgramFiles%\WinSCP\WinSCP.com
) else if exist "%ProgramFiles(x86)%\WinSCP\WinSCP.com" (
    set WINSCP_PATH=%ProgramFiles(x86)%\WinSCP\WinSCP.com
)

REM D 盘 WinSCP 文件夹（用户可能放在这里）
if exist "D:\WinSCP\WinSCP.com" (
    set WINSCP_PATH=D:\WinSCP\WinSCP.com
)

if "%WINSCP_PATH%"=="" (
    echo [错误] 未找到 WinSCP.com
    echo.
    echo WinSCP.com 未安装或未找到。
    echo.
    echo 解决方案:
    echo 1. 打开 WinSCP GUI
    echo 2. 菜单: 工具 -^> 安装命令行工具
    echo 3. 或从 https://winscp.net 下载便携版
    echo.
    echo 备选方案:
    echo - 运行 AUTO_DOWNLOAD_ALL.bat（需要手动输入密码）
    echo - 使用 WinSCP GUI 手动下载
    echo.
    pause
    exit /b 1
)

echo [找到] WinSCP.com: %WINSCP_PATH%
echo.

REM 创建本地目录
echo [准备] 创建本地目录...
if not exist "D:\scythe_training_backup\models" mkdir "D:\scythe_training_backup\models"
if not exist "D:\scythe_training_backup\binaries" mkdir "D:\scythe_training_backup\binaries"
if not exist "D:\scythe_training_backup\logs" mkdir "D:\scythe_training_backup\logs"
if not exist "D:\scythe_training_backup\exported" mkdir "D:\scythe_training_backup\exported"
echo [OK] 本地目录准备完成
echo.

REM 执行 WinSCP 脚本
echo [开始] 自动下载...
echo.
echo ========================================
echo 下载进度
echo ========================================
echo.

"%WINSCP_PATH%" /script="D:\ScytheKatago\winscp_download_script.txt" /log="D:\ScytheKatago\winscp_download.log"

if %ERRORLEVEL% == 0 (
    echo.
    echo ========================================
    echo [成功] 自动下载完成！
    echo ========================================
    echo.

    REM 验证下载结果
    echo [验证] 检查下载的文件...
    echo.

    if exist "D:\scythe_training_backup\models\model.txt.gz" (
        echo [OK] models\model.txt.gz - 已下载
        for %%F in ("D:\scythe_training_backup\models\model.txt.gz") do echo     大小: %%~zF 字节
    ) else (
        echo [失败] models\model.txt.gz - 缺失
    )

    if exist "D:\scythe_training_backup\binaries\katago" (
        echo [OK] binaries\katago - 已下载
        for %%F in ("D:\scythe_training_backup\binaries\katago") do echo     大小: %%~zF 字节
    ) else (
        echo [失败] binaries\katago - 缺失
    )

    if exist "D:\scythe_training_backup\logs\train_8gpu_daemon.log" (
        echo [OK] logs\train_8gpu_daemon.log - 已下载
        for %%F in ("D:\scythe_training_backup\logs\train_8gpu_daemon.log") do echo     大小: %%~zF 字节
    ) else (
        echo [失败] logs\train_8gpu_daemon.log - 缺失
    )

    echo.
    echo ========================================
    echo 下一步操作
    echo ========================================
    echo.
    echo 1. 查看下载日志: D:\ScytheKatago\winscp_download.log
    echo 2. 运行 CREATE_MIGRATION_PACKAGE.bat 创建迁移包
    echo 3. 租用新服务器并上传迁移包
    echo.

    REM 询问是否立即创建迁移包
    set /p CREATE_PKG="是否立即创建迁移包? (Y/N): "
    if /i "%CREATE_PKG%"=="Y" (
        echo.
        echo [执行] 创建迁移包...
        call "D:\ScytheKatago\CREATE_MIGRATION_PACKAGE.bat"
    )

) else (
    echo.
    echo ========================================
    echo [失败] 自动下载失败
    echo ========================================
    echo.
    echo 错误代码: %ERRORLEVEL%
    echo 查看日志: D:\ScytheKatago\winscp_download.log
    echo.
    echo 备选方案:
    echo 1. 使用 WinSCP GUI 手动下载
    echo 2. 运行 AUTO_DOWNLOAD_ALL.bat 并手动输入密码
    echo.
)

pause
