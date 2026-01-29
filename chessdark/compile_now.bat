@echo off
setlocal enabledelayedexpansion

REM Initialize VS environment
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1

cd /d D:\ScytheKatago\chessdark\stockfish11\src

REM Clean old files
del /q *.obj 2>nul
del /q darkchess\*.obj 2>nul
del /q syzygy\*.obj 2>nul
del /q stockfish.exe 2>nul

set CXXFLAGS=/std:c++17 /O2 /DNDEBUG /DIS_64BIT /EHsc /W3

echo ===== Compiling Stockfish Core =====
for %%f in (benchmark bitbase bitboard endgame evaluate main material misc movegen movepick pawns position psqt search thread timeman tt uci ucioption) do (
    echo Compiling %%f.cpp...
    cl /c !CXXFLAGS! /Fo:%%f.obj %%f.cpp >nul 2>&1
    if errorlevel 1 (
        echo ERROR compiling %%f.cpp
        cl /c !CXXFLAGS! /Fo:%%f.obj %%f.cpp
        exit /b 1
    )
)

echo ===== Compiling Syzygy =====
cl /c %CXXFLAGS% /Fo:syzygy\tbprobe.obj syzygy\tbprobe.cpp >nul 2>&1
if errorlevel 1 (
    echo ERROR compiling syzygy
    exit /b 1
)
echo OK

echo ===== Compiling DarkChess =====
echo Compiling darkboard.cpp...
cl /c %CXXFLAGS% /Fo:darkchess\darkboard.obj darkchess\darkboard.cpp
if errorlevel 1 (
    echo ERROR compiling darkboard.cpp
    exit /b 1
)

echo Compiling mcts.cpp...
cl /c %CXXFLAGS% /Fo:darkchess\mcts.obj darkchess\mcts.cpp
if errorlevel 1 (
    echo ERROR compiling mcts.cpp
    exit /b 1
)

echo ===== Linking =====
link /OUT:stockfish.exe *.obj syzygy\tbprobe.obj darkchess\*.obj >nul 2>&1
if errorlevel 1 (
    echo ERROR linking
    link /OUT:stockfish.exe *.obj syzygy\tbprobe.obj darkchess\*.obj
    exit /b 1
)

echo.
echo ===== Build Successful! =====
echo Output: D:\ScytheKatago\chessdark\stockfish11\src\stockfish.exe

endlocal
