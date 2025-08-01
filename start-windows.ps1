# December Windows 11 Startup Script
# PowerShell version for better error handling and modern Windows compatibility

Write-Host "Starting December on Windows 11..." -ForegroundColor Green

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "Docker is running ✓" -ForegroundColor Green
} catch {
    Write-Host "Error: Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    Write-Host "You can download Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if docker-compose is available
try {
    docker-compose --version | Out-Null
    Write-Host "Docker Compose is available ✓" -ForegroundColor Green
} catch {
    Write-Host "Error: Docker Compose is not available. Please install Docker Compose." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Copy config file to backend directory
Write-Host "Copying configuration file..." -ForegroundColor Yellow
Copy-Item "config.ts" "backend\config.ts" -Force

# Check if config file has default API key
$configContent = Get-Content "config.ts" -Raw
if ($configContent -match "your-api-key-here") {
    Write-Host "Warning: Default API key detected!" -ForegroundColor Red
    Write-Host "Please update your API key in config.ts before proceeding." -ForegroundColor Yellow
    Write-Host "Edit config.ts and replace 'your-api-key-here' with your actual API key." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

Write-Host "Building and starting containers..." -ForegroundColor Yellow
try {
    docker-compose -f docker-compose.windows.yml up --build
} catch {
    Write-Host "Error occurred during startup. Check the error messages above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "December is starting up..." -ForegroundColor Green
Write-Host "Frontend will be available at: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Backend API will be available at: http://localhost:4000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop all services." -ForegroundColor Yellow