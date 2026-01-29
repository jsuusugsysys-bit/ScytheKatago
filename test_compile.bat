@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cl.exe D:\ScytheKatago\test.cpp /Fe:D:\ScytheKatago\test.exe
if %errorlevel% equ 0 (
    echo [SUCCESS] Compiler works!
    D:\ScytheKatago\test.exe
) else (
    echo [FAIL] Compilation failed.
)
