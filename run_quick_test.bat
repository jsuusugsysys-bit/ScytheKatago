@echo off
set KATAGO=D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe
set MODEL=D:\2025-05-19-win64-RTX50XX特供版\weights\28b.bin.gz
set CONFIG=D:\ScytheKatago\scythe_config.cfg
set TEST_INPUT=D:\ScytheKatago\quick_test_fix.txt
set OUTPUT=D:\ScytheKatago\test_output.txt
set ERROR_OUT=D:\ScytheKatago\test_error.txt

echo Starting test at %date% %time% > %OUTPUT%
echo Checking if files exist... >> %OUTPUT%

if exist "%KATAGO%" (
    echo KataGo found: %KATAGO% >> %OUTPUT%
) else (
    echo ERROR: KataGo not found: %KATAGO% >> %OUTPUT%
    exit /b 1
)

if exist "%MODEL%" (
    echo Model found: %MODEL% >> %OUTPUT%
) else (
    echo ERROR: Model not found: %MODEL% >> %OUTPUT%
    exit /b 1
)

echo Running KataGo... >> %OUTPUT%
"%KATAGO%" gtp -model "%MODEL%" -config "%CONFIG%" < "%TEST_INPUT%" >> %OUTPUT% 2> %ERROR_OUT%
echo Exit code: %errorlevel% >> %OUTPUT%
echo Done at %date% %time% >> %OUTPUT%
