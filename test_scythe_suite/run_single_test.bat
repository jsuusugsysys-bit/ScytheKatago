@echo off
REM 运行单个测试文件
REM 用法: run_single_test.bat <测试文件名>
REM 例如: run_single_test.bat test_basic.txt

if "%~1"=="" (
    echo 用法: run_single_test.bat ^<测试文件名^>
    echo.
    echo 可用的测试文件:
    echo   test_basic.txt         - 基本功能测试
    echo   test_boundary.txt      - 边界条件测试
    echo   test_combo.txt         - 连击逻辑测试
    echo   test_count.txt         - 镰刀数量测试
    echo   test_both_players.txt  - 双方测试
    echo   test_board_size.txt    - 棋盘大小测试
    echo   test_reset.txt         - 重置功能测试
    echo.
    pause
    exit /b 1
)

set KATAGO_EXE=D:\ScytheKatago\katago.exe
set MODEL_PATH=D:\2025-05-19-win64-RTX50XX特供版\weights\28b.bin.gz
set CONFIG_PATH=D:\ScytheKatago\scythe_config.cfg
set TEST_DIR=D:\ScytheKatago\test_scythe_suite
set TEST_FILE=%TEST_DIR%\%~1

if not exist "%TEST_FILE%" (
    echo [错误] 找不到测试文件: %TEST_FILE%
    pause
    exit /b 1
)

echo ========================================
echo 运行测试: %~1
echo ========================================
echo.

"%KATAGO_EXE%" gtp -model "%MODEL_PATH%" -config "%CONFIG_PATH%" < "%TEST_FILE%"

echo.
echo ========================================
echo 测试完成
echo ========================================
pause
