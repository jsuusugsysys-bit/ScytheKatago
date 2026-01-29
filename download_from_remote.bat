@echo off
REM ========================================
REM 从远程服务器下载 KataGo 训练文件
REM ========================================

setlocal enabledelayedexpansion

echo ========================================
echo 远程服务器文件下载脚本
echo ========================================
echo.
echo 服务器: jxcb@123.181.192.94:60022
echo 本地目标: D:\ScytheKatago\remote_training\
echo.

REM 创建本地目录
echo [1/6] 创建本地目录...
if not exist "D:\ScytheKatago\remote_training" mkdir "D:\ScytheKatago\remote_training"
if not exist "D:\ScytheKatago\remote_training\configs" mkdir "D:\ScytheKatago\remote_training\configs"
if not exist "D:\ScytheKatago\remote_training\scripts" mkdir "D:\ScytheKatago\remote_training\scripts"
if not exist "D:\ScytheKatago\remote_training\logs" mkdir "D:\ScytheKatago\remote_training\logs"
if not exist "D:\ScytheKatago\remote_training\models" mkdir "D:\ScytheKatago\remote_training\models"
if not exist "D:\ScytheKatago\remote_training\katago_tensorrt" mkdir "D:\ScytheKatago\remote_training\katago_tensorrt"
if not exist "D:\ScytheKatago\installers" mkdir "D:\ScytheKatago\installers"
if not exist "D:\ScytheKatago\backups" mkdir "D:\ScytheKatago\backups"
echo 完成！
echo.

REM 生成 WinSCP 脚本
echo [2/6] 生成 WinSCP 脚本...
set SCRIPT_FILE=D:\ScytheKatago\winscp_download_script.txt

echo option batch abort > "%SCRIPT_FILE%"
echo option confirm off >> "%SCRIPT_FILE%"
echo open sftp://jxcb@123.181.192.94:60022/ -password=zOh17lGDsbmrcmX -hostkey=* >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

REM 下载 scythe_training 核心文件
echo cd /home/jxcb/scythe_training >> "%SCRIPT_FILE%"
echo lcd D:\ScytheKatago\remote_training >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 下载配置文件 >> "%SCRIPT_FILE%"
echo get -preservetime configs/* D:\ScytheKatago\remote_training\configs\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 下载脚本文件 >> "%SCRIPT_FILE%"
echo get -preservetime *.sh D:\ScytheKatago\remote_training\scripts\ >> "%SCRIPT_FILE%"
echo get -preservetime /home/jxcb/backup_training_data.sh D:\ScytheKatago\remote_training\scripts\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 下载最新日志（限制大小，只下载最近修改的文件） >> "%SCRIPT_FILE%"
echo get -preservetime -neweronly logs/*.log D:\ScytheKatago\remote_training\logs\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 下载模型文件（.bin.gz 文件） >> "%SCRIPT_FILE%"
echo get -preservetime *.bin.gz D:\ScytheKatago\remote_training\models\ >> "%SCRIPT_FILE%"
echo get -preservetime models/*.bin.gz D:\ScytheKatago\remote_training\models\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 下载 KataGo TensorRT 可执行文件 >> "%SCRIPT_FILE%"
echo get -preservetime katago/cpp/build/katago D:\ScytheKatago\remote_training\katago_tensorrt\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 下载 TensorRT 安装包（可选） >> "%SCRIPT_FILE%"
echo get -preservetime /home/jxcb/tensorrt.deb D:\ScytheKatago\installers\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo # 下载最新备份（可选） >> "%SCRIPT_FILE%"
echo get -preservetime -r /home/jxcb/backup_20260123 D:\ScytheKatago\backups\ >> "%SCRIPT_FILE%"
echo. >> "%SCRIPT_FILE%"

echo exit >> "%SCRIPT_FILE%"

echo 完成！
echo.

REM 检查 WinSCP 是否存在
echo [3/6] 检查 WinSCP 安装...
set WINSCP_EXE=
if exist "C:\Program Files (x86)\WinSCP\WinSCP.com" (
    set WINSCP_EXE=C:\Program Files ^(x86^)\WinSCP\WinSCP.com
    echo 找到 WinSCP: !WINSCP_EXE!
) else if exist "C:\Program Files\WinSCP\WinSCP.com" (
    set WINSCP_EXE=C:\Program Files\WinSCP\WinSCP.com
    echo 找到 WinSCP: !WINSCP_EXE!
) else if exist "%ProgramFiles(x86)%\WinSCP\WinSCP.com" (
    set WINSCP_EXE=%ProgramFiles(x86)%\WinSCP\WinSCP.com
    echo 找到 WinSCP: !WINSCP_EXE!
) else if exist "%ProgramFiles%\WinSCP\WinSCP.com" (
    set WINSCP_EXE=%ProgramFiles%\WinSCP\WinSCP.com
    echo 找到 WinSCP: !WINSCP_EXE!
) else (
    echo [错误] 未找到 WinSCP，请手动指定路径
    echo.
    echo 请编辑此脚本，在第 95 行设置 WINSCP_EXE 变量为您的 WinSCP.com 路径
    echo 例如: set WINSCP_EXE=D:\WinSCP\WinSCP.com
    pause
    exit /b 1
)
echo.

REM 确认下载
echo [4/6] 准备下载...
echo.
echo ========================================
echo 将下载以下内容:
echo ========================================
echo 1. scythe_training/configs/          (训练配置文件)
echo 2. scythe_training/*.sh              (启动脚本)
echo 3. scythe_training/logs/*.log        (最新日志)
echo 4. scythe_training/models/*.bin.gz   (模型文件)
echo 5. katago TensorRT 可执行文件
echo 6. tensorrt.deb                      (TensorRT 安装包)
echo 7. backup_20260123/                  (最新备份)
echo ========================================
echo.
echo 注意: 不会下载 selfplay/ 目录 (太大，48GB)
echo.
set /p CONFIRM="确认开始下载? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 已取消下载
    pause
    exit /b 0
)
echo.

REM 执行下载
echo [5/6] 开始下载...
echo.
"%WINSCP_EXE%" /script="%SCRIPT_FILE%" /log="D:\ScytheKatago\winscp_download.log"

if %errorlevel% neq 0 (
    echo.
    echo [错误] 下载过程中出现错误！
    echo 请查看日志: D:\ScytheKatago\winscp_download.log
    pause
    exit /b 1
)

echo.
echo [6/6] 下载完成！
echo.

REM 显示结果
echo ========================================
echo 下载结果
echo ========================================
echo 文件已下载到:
echo - 配置文件: D:\ScytheKatago\remote_training\configs\
echo - 脚本文件: D:\ScytheKatago\remote_training\scripts\
echo - 日志文件: D:\ScytheKatago\remote_training\logs\
echo - 模型文件: D:\ScytheKatago\remote_training\models\
echo - TensorRT: D:\ScytheKatago\remote_training\katago_tensorrt\
echo - 安装包:   D:\ScytheKatago\installers\
echo - 备份:     D:\ScytheKatago\backups\
echo.
echo 日志文件: D:\ScytheKatago\winscp_download.log
echo ========================================
echo.

REM 清理临时脚本
echo 是否删除临时脚本文件?
set /p CLEANUP="删除 %SCRIPT_FILE%? (Y/N): "
if /i "%CLEANUP%"=="Y" (
    del "%SCRIPT_FILE%"
    echo 已删除临时脚本
)
echo.

echo 全部完成！
pause
