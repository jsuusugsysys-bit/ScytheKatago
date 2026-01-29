# Build ChessDark with MSVC via PowerShell

# Import VS environment
$vsPath = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

# Use cmd to setup environment and build
$buildScript = @"
@echo off
call "$vsPath"
cd /d D:\ScytheKatago\chessdark\stockfish11\src
echo Cleaning...
del /q *.obj 2>nul
del /q darkchess\*.obj 2>nul

set CXXFLAGS=/std:c++17 /O2 /DNDEBUG /DIS_64BIT /EHsc /W3 /I.

echo Compiling darkboard.cpp...
cl /c %CXXFLAGS% /Fo:darkchess\darkboard.obj darkchess\darkboard.cpp
if errorlevel 1 exit /b 1

echo Compiling mcts.cpp...
cl /c %CXXFLAGS% /Fo:darkchess\mcts.obj darkchess\mcts.cpp
if errorlevel 1 exit /b 1

echo Compiling core files...
for %%f in (benchmark bitbase bitboard endgame evaluate main material misc movegen movepick pawns position psqt search thread timeman tt uci ucioption) do (
    cl /c %CXXFLAGS% /Fo:%%f.obj %%f.cpp
    if errorlevel 1 exit /b 1
)

echo Compiling syzygy...
cl /c %CXXFLAGS% /Fo:syzygy\tbprobe.obj syzygy\tbprobe.cpp
if errorlevel 1 exit /b 1

echo Linking...
link /OUT:stockfish.exe *.obj syzygy\tbprobe.obj darkchess\*.obj
if errorlevel 1 exit /b 1

echo.
echo === Build Successful ===
"@

$tempBat = "$env:TEMP\build_chessdark.bat"
$buildScript | Out-File -FilePath $tempBat -Encoding ASCII

& cmd.exe /c $tempBat
