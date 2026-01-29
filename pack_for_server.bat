@echo off
chcp 65001 >nul
echo ============================================
echo 打包镰刀训练文件到服务器
echo ============================================
echo.

cd /d D:\ScytheKatago
if errorlevel 1 (
    echo 错误：无法进入目录 D:\ScytheKatago
    pause
    exit /b 1
)

echo 当前目录: %CD%
echo.

echo [1/4] 创建上传目录...
if exist upload_package (
    echo     删除旧目录...
    rmdir /s /q upload_package
)
mkdir upload_package
if errorlevel 1 (
    echo 错误：无法创建目录
    pause
    exit /b 1
)
echo     完成
echo.

echo [2/4] 复制 KataGo 源码（这一步较慢，请等待）...
xcopy /E /I /Y /Q KataGo upload_package\katago
if errorlevel 1 (
    echo 错误：复制 KataGo 失败
    pause
    exit /b 1
)
echo     完成
echo.

echo [3/4] 复制训练脚本...
xcopy /E /I /Y /Q training upload_package\training
if errorlevel 1 (
    echo 错误：复制训练脚本失败
    pause
    exit /b 1
)
echo     完成
echo.

echo [4/4] 复制棋谱文件...
if exist "飞刀.tar.xz" (
    copy "飞刀.tar.xz" upload_package\
    echo     完成
) else (
    echo     警告：棋谱文件不存在，跳过
)
echo.

echo ============================================
echo 打包完成！
echo.
echo 文件位置: D:\ScytheKatago\upload_package\
echo.
echo 下一步：用 WinSCP 上传到服务器
echo ============================================
echo.
echo 按任意键关闭此窗口...
pause >nul
