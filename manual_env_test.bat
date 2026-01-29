@echo off
echo [START] Manual Config Test (Console Output)

REM --- 1. 定义关键路径 ---
set MSVC_ROOT=C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717
set SDK_ROOT=C:\Program Files (x86)\Windows Kits\10
set SDK_VER=10.0.26100.0

REM --- 2. 手动设置 INCLUDE (头文件) ---
set INCLUDE=%MSVC_ROOT%\include;%SDK_ROOT%\Include\%SDK_VER%\ucrt;%SDK_ROOT%\Include\%SDK_VER%\um;%SDK_ROOT%\Include\%SDK_VER%\shared;%INCLUDE%

REM --- 3. 手动设置 LIB (库文件) ---
set LIB=%MSVC_ROOT%\lib\x64;%SDK_ROOT%\Lib\%SDK_VER%\ucrt\x64;%SDK_ROOT%\Lib\%SDK_VER%\um\x64;%LIB%

REM --- 4. 手动设置 PATH (编译器) ---
set PATH=%MSVC_ROOT%\bin\Hostx64\x64;%PATH%

REM --- 5. 编译 ---
echo [COMPILE] Running cl.exe...
cl.exe /EHsc D:\ScytheKatago\test.cpp /Fe:D:\ScytheKatago\test.exe

if %errorlevel% equ 0 (
    echo [SUCCESS] Compilation Worked!
) else (
    echo [FAIL] Compilation Failed!
)

