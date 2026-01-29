@echo off
REM Build ChessDark with MSVC

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

cd /d D:\ScytheKatago\chessdark\stockfish11\src

REM Clean
del /q *.o 2>nul
del /q darkchess\*.o 2>nul
del /q syzygy\*.o 2>nul
del /q stockfish.exe 2>nul

REM Compile each source file
set CXXFLAGS=/std:c++17 /O2 /DNDEBUG /DIS_64BIT /EHsc /W3

echo Compiling Stockfish core...
for %%f in (benchmark bitbase bitboard endgame evaluate main material misc movegen movepick pawns position psqt search thread timeman tt uci ucioption) do (
    echo   %%f.cpp
    cl /c %CXXFLAGS% /Fo:%%f.obj %%f.cpp
    if errorlevel 1 goto :error
)

echo Compiling syzygy...
cl /c %CXXFLAGS% /Fo:syzygy\tbprobe.obj syzygy\tbprobe.cpp
if errorlevel 1 goto :error

echo Compiling darkchess...
cl /c %CXXFLAGS% /Fo:darkchess\darkboard.obj darkchess\darkboard.cpp
if errorlevel 1 goto :error

cl /c %CXXFLAGS% /Fo:darkchess\mcts.obj darkchess\mcts.cpp
if errorlevel 1 goto :error

echo Linking...
link /OUT:stockfish.exe *.obj syzygy\tbprobe.obj darkchess\*.obj
if errorlevel 1 goto :error

echo.
echo Build successful! Output: stockfish.exe
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
