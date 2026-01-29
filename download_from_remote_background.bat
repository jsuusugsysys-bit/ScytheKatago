@echo off
REM ========================================
REM 后台下载脚本 - 即使关闭 Claude 也继续下载
REM ========================================

setlocal enabledelayedexpansion

REM 创建本地目录（静默）
if not exist "D:\ScytheKatago\remote_training" mkdir "D:\ScytheKatago\remote_training"
if not exist "D:\ScytheKatago\remote_training\configs" mkdir "D:\ScytheKatago\remote_training\configs"
if not exist "D:\ScytheKatago\remote_training\scripts" mkdir "D:\ScytheKatago\remote_training\scripts"
if not exist "D:\ScytheKatago\remote_training\logs" mkdir "D:\ScytheKatago\remote_training\logs"
if not exist "D:\ScytheKatago\remote_training\models" mkdir "D:\ScytheKatago\remote_training\models"
if not exist "D:\ScytheKatago\remote_training\katago_tensorrt" mkdir "D:\ScytheKatago\remote_training\katago_tensorrt"
if not exist "D:\ScytheKatago\installers" mkdir "D:\ScytheKatago\installers"
if not exist "D:\ScytheKatago\backups" mkdir "D:\ScytheKatago\backups"

REM 生成 WinSCP 脚本
set SCRIPT_FILE=D:\ScytheKatago\winscp_download_script.txt

echo option batch abort > "%SCRIPT_FILE%"
echo option confirm off >> "%SCRIPT_FILE%"
echo open sftp://jxcb@123.181.192.94:60022/ -password=zOh17lGDsbmrcmX -hostkey=* >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

REM 下载命令
echo cd /home/jxcb/scythe_training >> "%SCRIPT_FILE%"
echo lcd D:\ScytheKatago\remote_training >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 配置文件 >> "%SCRIPT_FILE%"
echo get -preservetime configs/* D:\ScytheKatago\remote_training\configs\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 脚本文件 >> "%SCRIPT_FILE%"
echo get -preservetime *.sh D:\ScytheKatago\remote_training\scripts\ >> "%SCRIPT_FILE%"
echo get -preservetime /home/jxcb/backup_training_data.sh D:\ScytheKatago\remote_training\scripts\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 最新日志 >> "%SCRIPT_FILE%"
echo get -preservetime logs/*.log D:\ScytheKatago\remote_training\logs\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 模型文件 >> "%SCRIPT_FILE%"
echo get -preservetime *.bin.gz D:\ScytheKatago\remote_training\models\ >> "%SCRIPT_FILE%"
echo get -preservetime models/*.bin.gz D:\ScytheKatago\remote_training\models\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # KataGo TensorRT 可执行文件 >> "%SCRIPT_FILE%"
echo get -preservetime katago/cpp/build/katago D:\ScytheKatago\remote_training\katago_tensorrt\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # TensorRT 安装包 >> "%SCRIPT_FILE%"
echo get -preservetime /home/jxcb/tensorrt.deb D:\ScytheKatago\installers\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 最新备份 >> "%SCRIPT_FILE%"
echo get -preservetime -r /home/jxcb/backup_20260123 D:\ScytheKatago\backups\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo exit >> "%SCRIPT_FILE%"

REM 查找 WinSCP
set WINSCP_EXE=
if exist "C:\Program Files (x86)\WinSCP\WinSCP.com" set WINSCP_EXE=C:\Program Files (x86)\WinSCP\WinSCP.com
if exist "C:\Program Files\WinSCP\WinSCP.com" set WINSCP_EXE=C:\Program Files\WinSCP\WinSCP.com

if not defined WINSCP_EXE (
    echo [错误] 未找到 WinSCP.com
    echo 下载失败，请手动运行 download_from_remote.bat
    echo. > D:\ScytheKatago\download_error.txt
    echo [错误] 未找到 WinSCP >> D:\ScytheKatago\download_error.txt
    exit /b 1
)

REM 后台执行下载（使用 start /min 最小化窗口）
echo [%date% %time%] 开始后台下载... > D:\ScytheKatago\download_status.txt
echo 服务器: jxcb@123.181.192.94:60022 >> D:\ScytheKatago\download_status.txt
echo. >> D:\ScytheKatago\download_status.txt

start /min "远程文件下载中..." "%WINSCP_EXE%" /script="%SCRIPT_FILE%" /log="D:\ScytheKatago\winscp_download.log"

REM 等待一下确保启动
timeout /t 2 /nobreak > nul

echo [%date% %time%] WinSCP 进程已启动 >> D:\ScytheKatago\download_status.txt
echo 即使关闭此窗口，下载也会继续 >> D:\ScytheKatago\download_status.txt
echo. >> D:\ScytheKatago\download_status.txt
echo 查看进度: D:\ScytheKatago\winscp_download.log >> D:\ScytheKatago\download_status.txt
echo. >> D:\ScytheKatago\download_status.txt

echo ========================================
echo 后台下载已启动！
echo ========================================
echo.
echo 下载进程正在后台运行（最小化窗口）
echo 即使关闭 Claude 或此窗口，下载也会继续
echo.
echo 查看下载状态:
echo   状态文件: D:\ScytheKatago\download_status.txt
echo   详细日志: D:\ScytheKatago\winscp_download.log
echo.
echo 下载完成后文件位置:
echo   D:\ScytheKatago\remote_training\
echo.
echo 可以安全关闭此窗口了
echo ========================================

REM 等待 5 秒后自动关闭
timeout /t 5
