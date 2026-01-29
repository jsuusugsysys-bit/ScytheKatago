@echo off
REM 镰刀功能自动化测试套件
REM 运行所有测试并生成报告

setlocal enabledelayedexpansion

echo ========================================
echo 镰刀功能自动化测试套件
echo ========================================
echo.

set KATAGO_EXE=D:\ScytheKatago\katago.exe
set MODEL_PATH=D:\2025-05-19-win64-RTX50XX特供版\weights\28b.bin.gz
set CONFIG_PATH=D:\ScytheKatago\scythe_config.cfg
set TEST_DIR=D:\ScytheKatago\test_scythe_suite
set RESULT_DIR=%TEST_DIR%\results
set TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

REM 创建结果目录
if not exist "%RESULT_DIR%" mkdir "%RESULT_DIR%"

REM 创建本次测试的结果目录
set CURRENT_RESULT_DIR=%RESULT_DIR%\test_%TIMESTAMP%
mkdir "%CURRENT_RESULT_DIR%"

echo 测试时间: %date% %time%
echo 结果目录: %CURRENT_RESULT_DIR%
echo.

REM 检查 KataGo 可执行文件
if not exist "%KATAGO_EXE%" (
    echo [错误] 找不到 KataGo 可执行文件: %KATAGO_EXE%
    echo 请先运行 build.bat 或 compile.bat 编译项目
    pause
    exit /b 1
)

REM 检查模型文件
if not exist "%MODEL_PATH%" (
    echo [警告] 找不到神经网络模型: %MODEL_PATH%
    echo 测试将继续，但可能会失败
    echo.
)

REM 检查配置文件
if not exist "%CONFIG_PATH%" (
    echo [错误] 找不到配置文件: %CONFIG_PATH%
    pause
    exit /b 1
)

REM 测试列表
set TEST_FILES=test_basic.txt test_boundary.txt test_combo.txt test_count.txt test_both_players.txt test_board_size.txt test_reset.txt

set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0

REM 运行每个测试
for %%T in (%TEST_FILES%) do (
    set /a TOTAL_TESTS+=1
    echo ========================================
    echo 运行测试: %%T
    echo ========================================

    set TEST_FILE=%TEST_DIR%\%%T
    set OUTPUT_FILE=%CURRENT_RESULT_DIR%\%%~nT_output.txt
    set ERROR_FILE=%CURRENT_RESULT_DIR%\%%~nT_error.txt

    REM 运行测试
    "%KATAGO_EXE%" gtp -model "%MODEL_PATH%" -config "%CONFIG_PATH%" < "!TEST_FILE!" > "!OUTPUT_FILE!" 2> "!ERROR_FILE!"

    REM 检查是否成功
    if !ERRORLEVEL! EQU 0 (
        echo [通过] %%T
        set /a PASSED_TESTS+=1
    ) else (
        echo [失败] %%T - 错误代码: !ERRORLEVEL!
        set /a FAILED_TESTS+=1
    )
    echo.
)

REM 生成测试报告
set REPORT_FILE=%CURRENT_RESULT_DIR%\test_report.txt

echo ======================================== > "%REPORT_FILE%"
echo 镰刀功能测试报告 >> "%REPORT_FILE%"
echo ======================================== >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"
echo 测试时间: %date% %time% >> "%REPORT_FILE%"
echo KataGo 版本: %KATAGO_EXE% >> "%REPORT_FILE%"
echo 神经网络: %MODEL_PATH% >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"
echo ---------------------------------------- >> "%REPORT_FILE%"
echo 测试统计 >> "%REPORT_FILE%"
echo ---------------------------------------- >> "%REPORT_FILE%"
echo 总测试数: %TOTAL_TESTS% >> "%REPORT_FILE%"
echo 通过: %PASSED_TESTS% >> "%REPORT_FILE%"
echo 失败: %FAILED_TESTS% >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"
echo ---------------------------------------- >> "%REPORT_FILE%"
echo 测试详情 >> "%REPORT_FILE%"
echo ---------------------------------------- >> "%REPORT_FILE%"

for %%T in (%TEST_FILES%) do (
    echo. >> "%REPORT_FILE%"
    echo [%%T] >> "%REPORT_FILE%"
    set OUTPUT_FILE=%CURRENT_RESULT_DIR%\%%~nT_output.txt
    if exist "!OUTPUT_FILE!" (
        echo   输出文件: %%~nT_output.txt >> "%REPORT_FILE%"
        echo   错误文件: %%~nT_error.txt >> "%REPORT_FILE%"
    ) else (
        echo   [未运行] >> "%REPORT_FILE%"
    )
)

echo. >> "%REPORT_FILE%"
echo ======================================== >> "%REPORT_FILE%"
echo 测试完成 >> "%REPORT_FILE%"
echo ======================================== >> "%REPORT_FILE%"

REM 显示测试报告
echo.
echo ========================================
echo 测试完成
echo ========================================
echo.
type "%REPORT_FILE%"
echo.
echo 详细结果保存在: %CURRENT_RESULT_DIR%
echo.

REM 如果有失败的测试，返回错误代码
if %FAILED_TESTS% GTR 0 (
    echo [警告] 有 %FAILED_TESTS% 个测试失败
    echo 请查看错误日志文件了解详情
    pause
    exit /b 1
) else (
    echo [成功] 所有测试通过！
    pause
    exit /b 0
)
