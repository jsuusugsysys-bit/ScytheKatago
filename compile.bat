@echo off
chcp 65001 >nul
echo ========================================
echo Compiling Lizzieyzy (Scythe Fix)
echo ========================================
echo.

cd /d "d:\ScytheKatago\lizzieyzy-main"

echo [1/2] Cleaning...
call mvn clean

echo.
echo [2/2] Building...
call mvn package -DskipTests

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS!
    echo ========================================
    echo.
    echo Output: target\lizzie-yzy2.5.3-shaded.jar
    echo.
    echo To run:
    echo cd /d d:\ScytheKatago\lizzieyzy-main\target
    echo java -jar lizzie-yzy2.5.3-shaded.jar
    echo.
) else (
    echo.
    echo ========================================
    echo FAILED!
    echo ========================================
    echo Check error messages above
)

pause
