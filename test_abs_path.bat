@echo off
set LOG=D:\ScytheKatago\compiler_test.log
echo [START] Absolute Path Compiler Test > %LOG%

REM 1. 尝试设置环境 (为了 INCLUDE 和 LIB 变量)
echo [ENV] Calling vcvars64.bat... >> %LOG%
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >> %LOG% 2>&1

REM 2. 定义编译器绝对路径
set CL_PATH="C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\cl.exe"

REM 3. 尝试编译
echo [COMPILE] Trying to compile test.cpp... >> %LOG%
%CL_PATH% D:\ScytheKatago\test.cpp /Fe:D:\ScytheKatago\test.exe >> %LOG% 2>&1

if %errorlevel% equ 0 (
    echo [SUCCESS] Compilation Succeeded! >> %LOG%
    echo [RUN] Running test.exe... >> %LOG%
    D:\ScytheKatago\test.exe >> %LOG% 2>&1
) else (
    echo [FAIL] Compilation Failed! >> %LOG%
    echo [DEBUG] Environment Variables: >> %LOG%
    set INCLUDE >> %LOG% 2>&1
)
