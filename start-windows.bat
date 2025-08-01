@echo off
echo Starting December on Windows 11...

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

REM Copy config file to backend directory
echo Copying configuration file...
copy config.ts backend\config.ts

REM Check if config file has default API key
findstr "your-api-key-here" config.ts >nul
if %errorlevel% equ 0 (
    echo Warning: Please update your API key in config.ts before proceeding.
    echo Edit config.ts and replace "your-api-key-here" with your actual API key.
    pause
)

echo Building and starting containers...
docker-compose -f docker-compose.windows.yml up --build

echo.
echo December is starting up...
echo Frontend will be available at: http://localhost:3000
echo Backend API will be available at: http://localhost:4000
echo.
echo Press Ctrl+C to stop all services.
pause