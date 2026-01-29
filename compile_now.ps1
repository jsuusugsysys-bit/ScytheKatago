# PowerShell script to compile KataGo
$ErrorActionPreference = "Continue"

# Find MSBuild (try VS 2022 first, then VS 2019)
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path $msbuild)) {
    $msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
}

if (-not (Test-Path $msbuild)) {
    Write-Host "ERROR: MSBuild not found"
    exit 1
}

Write-Host "Using MSBuild: $msbuild"

# Change to build directory
Set-Location "D:\ScytheKatago\KataGo\cpp\build"

# Build the solution
Write-Host "=== Building KataGo ==="
& $msbuild "katago.sln" /p:Configuration=Release /m /v:minimal

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== BUILD SUCCESS ==="

    # Copy to scythe_lizzie
    Copy-Item "Release\katago.exe" "D:\ScytheKatago\scythe_lizzie\katago.exe" -Force
    Write-Host "Copied katago.exe to scythe_lizzie"
} else {
    Write-Host ""
    Write-Host "=== BUILD FAILED ==="
    exit 1
}
