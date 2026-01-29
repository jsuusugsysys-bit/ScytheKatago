@echo off
chcp 65001 >nul
echo ========================================
echo Starting Lizzieyzy (Scythe Version)
echo ========================================
echo.

REM Set Java path
set PATH=d:\ScytheKatago\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64\bin;%PATH%

REM Navigate to target directory
cd /d "d:\ScytheKatago\lizzieyzy-main\target"

echo Starting Lizzieyzy...
echo.
echo Test Steps:
echo 1. Create 11x11 board
echo 2. Play to move 11
echo 3. Click scythe button (black circle)
echo 4. Observe: Should play 3 consecutive black moves
echo 5. Check: Scythe count should decrease from 3 to 2
echo.
echo Press Ctrl+C to exit when done
echo.

java -jar lizzie-yzy2.5.3-shaded.jar

pause
