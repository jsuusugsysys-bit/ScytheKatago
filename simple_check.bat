@echo off
echo [TEST] Checking Visual Studio Compiler...

REM 1. 呼叫环境脚本
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1

REM 2. 检查 cl.exe 是否存在
where cl.exe
if %errorlevel% neq 0 (
    echo [FAIL] 找不到 cl.exe！环境配置失败。
) else (
    echo [OK] 发现编译器：
    cl.exe 2>&1 | findstr "Version"
)

REM 3. 检查 CMake
cmake --version | findstr "version"
