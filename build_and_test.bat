@echo off
chcp 65001 >nul
echo ========================================
echo Complete Build and Test Workflow
echo ========================================
echo.

echo [Step 1/2] Compiling KataGo...
echo.

REM Set up Visual Studio environment
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

REM Add CMake to PATH
set "PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"

cd /d "D:\ScytheKatago\KataGo\cpp\build"
cmake --build . --config Release --parallel 4

if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo COMPILATION FAILED!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo COMPILATION SUCCESS!
echo ========================================
echo.

echo [Step 2/2] Starting Lizzieyzy for testing...
echo.
echo Test Instructions:
echo 1. Create 11x11 board
echo 2. Play to move 11
echo 3. Click scythe button (black circle)
echo 4. Observe: Should play 3 consecutive black moves
echo 5. Check: Scythe count should decrease from 3 to 2
echo.
pause

REM Set Java path
set PATH=d:\ScytheKatago\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64\bin;%PATH%

cd /d "d:\ScytheKatago\lizzieyzy-main\target"
java -jar lizzie-yzy2.5.3-shaded.jar
