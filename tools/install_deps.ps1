# Right-click this file and select "Run with PowerShell"
Write-Host "Installing Python dependencies..." -ForegroundColor Green

# Try different methods
$pythonPaths = @(
    "python",
    "python3",
    "py",
    "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe"
)

$installed = $false
foreach ($pyPath in $pythonPaths) {
    try {
        $resolved = Get-Command $pyPath -ErrorAction SilentlyContinue
        if ($resolved) {
            Write-Host "Found Python at: $($resolved.Source)" -ForegroundColor Yellow
            & $resolved.Source -m pip install opencv-python pyautogui pillow pygetwindow numpy
            if ($LASTEXITCODE -eq 0) {
                $installed = $true
                break
            }
        }
    } catch {
        continue
    }
}

if (-not $installed) {
    Write-Host ""
    Write-Host "Auto-install failed. Please run this command manually:" -ForegroundColor Red
    Write-Host ""
    Write-Host "pip install opencv-python pyautogui pillow pygetwindow numpy" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
