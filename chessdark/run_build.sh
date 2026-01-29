#!/bin/bash
cd /d/ScytheKatago/chessdark
/mnt/c/Windows/System32/cmd.exe /c "compile_now.bat" > build_output.txt 2>&1
echo "Build completed. Exit code: $?"
