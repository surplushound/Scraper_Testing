$currentDir = Split-Path $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $currentDir "start-n8n.ps1"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Start n8n.lnk"

$wshell = New-Object -ComObject WScript.Shell
$shortcut = $wshell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
$shortcut.WorkingDirectory = $currentDir
$shortcut.Description = "Start n8n with Docker and ngrok"
$shortcut.IconLocation = "powershell.exe"
$shortcut.Save()

Write-Host "Shortcut created on desktop: Start n8n" -ForegroundColor Green
