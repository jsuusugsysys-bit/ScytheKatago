$WshShell = New-Object -ComObject WScript.Shell
$Desktop = [Environment]::GetFolderPath('Desktop')
$ShortcutPath = Join-Path $Desktop 'Scythe LizzieYzy.lnk'
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = 'D:\ScytheKatago\ScytheRelease\start_scythe.bat'
$Shortcut.WorkingDirectory = 'D:\ScytheKatago\ScytheRelease'
$Shortcut.Description = 'Scythe Katago Training GUI'
$Shortcut.Save()
Write-Host "Shortcut created at: $ShortcutPath"
