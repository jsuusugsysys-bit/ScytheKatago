@echo off
set LOG=D:\ScytheKatago\env_test.log
echo [START] Environment Test > %LOG%

REM 1. Activate VS Environment
echo [STEP 1] Activating VS Environment... >> %LOG%
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Failed to call vcvars64.bat >> %LOG%
    exit /b 1
)

REM 2. Check C++ Compiler (cl.exe)
echo [STEP 2] Checking cl.exe... >> %LOG%
where cl.exe >> %LOG% 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] cl.exe NOT found! >> %LOG%
    exit /b 1
)
cl.exe >> %LOG% 2>&1

REM 3. Check CMake
echo [STEP 3] Checking cmake... >> %LOG%
set "PATH=%PATH%;C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
where cmake.exe >> %LOG% 2>&1
cmake --version >> %LOG% 2>&1

echo [SUCCESS] Environment is OK! >> %LOG%
