@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d d:\ScytheKatago\chessdark\stockfish11\src
make clean
make build ARCH=x86-64 COMP=msvc
echo Build Complete.
