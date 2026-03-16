# start-n8n-robust.ps1
# This script ensures a clean, working n8n environment.

$currentDir = Split-Path $MyInvocation.MyCommand.Path
Set-Location $currentDir

Write-Host "--- n8n Power Start ---" -ForegroundColor Cyan

# 1. Clean up stale containers and port conflicts
Write-Host "[1/4] Cleaning up existing containers..." -ForegroundColor Yellow
docker-compose down --remove-orphans 2>$null
$conflicts = docker ps -q --filter "publish=5678"
if ($conflicts) {
    Write-Host "Found port 5678 conflict, stopping: $conflicts" -ForegroundColor Red
    docker stop $conflicts 2>$null
    docker rm $conflicts 2>$null
}

# 2. Start the environment
Write-Host "[2/4] Starting n8n and ngrok..." -ForegroundColor Yellow
docker-compose up -d --force-recreate

if ($LASTEXITCODE -ne 0) {
    Write-Host "CRITICAL ERROR: Docker failed to start. Is Docker Desktop running?" -ForegroundColor Red
    exit
}

# 3. Wait for ngrok URL
Write-Host "[3/4] Initializing external access..." -ForegroundColor Yellow
$maxRetries = 10
$retryCount = 0
$ngrokUrl = ""

while ($retryCount -lt $maxRetries -and -not $ngrokUrl) {
    Start-Sleep -Seconds 3
    $ngrokUrl = docker exec n8n-docker-ngrok-1 curl -s http://localhost:4040/api/tunnels | ConvertFrom-Json | Select-Object -ExpandProperty tunnels | Where-Object { $_.proto -eq 'https' } | Select-Object -ExpandProperty public_url
    $retryCount++
    if (-not $ngrokUrl) { Write-Host "." -NoNewline }
}

# 4. Final Output
Write-Host "`n[4/4] Success! Environment is ready." -ForegroundColor Green
Write-Host "--------------------------------------"
Write-Host "Local Access:    http://localhost:5678" -ForegroundColor White
if ($ngrokUrl) {
    Write-Host "External Access: $ngrokUrl" -ForegroundColor Cyan
}
else {
    Write-Host "External Access: Waiting for ngrok (Check logs if this persists)" -ForegroundColor Gray
}
Write-Host "--------------------------------------"

# Open n8n
Start-Process "http://localhost:5678"
