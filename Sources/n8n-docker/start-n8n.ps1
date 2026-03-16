$currentDir = Split-Path $MyInvocation.MyCommand.Path
Set-Location $currentDir

Write-Host "Checking Docker status..." -ForegroundColor Cyan
try {
    docker version | Out-Null
}
catch {
    Write-Host "`nError: Docker is not running or unreachable." -ForegroundColor Red
    Write-Host "Please start Docker Desktop and wait for it to be fully initialized." -ForegroundColor Yellow
    Write-Host "`nPress any key to close this window..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "Starting n8n and ngrok containers..." -ForegroundColor Cyan
docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nError: Failed to start containers. Check if Docker Desktop is running and initialized." -ForegroundColor Red
    Write-Host "`nPress any key to close this window..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "`nWaiting for ngrok to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$ngrokUrl = docker-compose exec ngrok curl -s http://localhost:4040/api/tunnels | ConvertFrom-Json | Select-Object -ExpandProperty tunnels | Where-Object { $_.proto -eq 'https' } | Select-Object -ExpandProperty public_url

if ($ngrokUrl) {
    Write-Host "`nn8n is starting!" -ForegroundColor Green
    Write-Host "Local URL: http://localhost:5678" -ForegroundColor Gray
    Write-Host "External URL: $ngrokUrl" -ForegroundColor Gray
    
    # Open n8n in the browser
    Start-Process "http://localhost:5678"
    
    Write-Host "`n--- Container Logs (Press Ctrl+C to stop viewing logs) ---" -ForegroundColor Cyan
    docker-compose logs -f n8n
}
else {
    Write-Host "`nContainers started, but couldn't retrieve ngrok URL." -ForegroundColor Red
    Write-Host "Check your NGROK_AUTHTOKEN in the .env file." -ForegroundColor Red
    Write-Host "`nPress any key to close this window or Ctrl+C to exit..."
    docker-compose logs n8n
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
