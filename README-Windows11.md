# December - Windows 11 Deployment Guide

This guide will help you deploy December on Windows 11 using Docker Desktop. December is an open-source alternative to AI-powered development platforms like Loveable, Replit, and Bolt that you can run locally with complete privacy and cost savings.

## Prerequisites

### 1. Windows 11 Requirements
- Windows 11 Pro, Enterprise, or Education (required for Docker Desktop)
- WSL 2 (Windows Subsystem for Linux 2)
- 8GB RAM minimum (16GB recommended)
- 50GB free disk space

### 2. Docker Desktop for Windows
Download and install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop/

**Important Installation Notes:**
- Enable WSL 2 backend during installation
- Ensure virtualization is enabled in BIOS
- Restart your computer after installation

### 3. Git for Windows
Download from: https://git-scm.com/download/win

## Installation Steps

### Step 1: Clone the Repository
Open PowerShell or Command Prompt and run:
```powershell
git clone https://github.com/ntegrals/december.git
cd december
```

### Step 2: Configure API Keys
1. Open `config.ts` in your preferred text editor
2. Replace `"your-api-key-here"` with your actual API key
3. Recommended: Use Anthropic Claude Sonnet 4 for best results

**Example configuration:**
```typescript
export const config = {
  aiSdk: {
    baseUrl: "https://openrouter.ai/api/v1",
    apiKey: "sk-your-actual-api-key-here",
    model: "anthropic/claude-sonnet-4",
  },
} as const;
```

### Step 3: Start December

#### Option A: Using PowerShell Script (Recommended)
```powershell
.\start-windows.ps1
```

#### Option B: Using Batch Script
```cmd
start-windows.bat
```

#### Option C: Manual Docker Compose
```powershell
docker-compose -f docker-compose.windows.yml up --build
```

### Step 4: Access the Application
Once the containers are running:
- **Frontend (Main App):** http://localhost:3000
- **Backend API:** http://localhost:4000

## Windows-Specific Features

### Enhanced Docker Configuration
The Windows deployment includes:
- **Named volumes** for better performance on Windows filesystems
- **Optimized networking** using bridge drivers
- **Bind mount optimization** for source code directories
- **Windows path handling** in volume configurations

### Startup Scripts
Two startup options are provided:

1. **PowerShell Script** (`start-windows.ps1`):
   - Modern PowerShell with colored output
   - Better error handling and validation
   - Docker health checks
   - Automatic API key validation

2. **Batch Script** (`start-windows.bat`):
   - Compatible with older Windows systems
   - Simple command-line interface
   - Basic error handling

### Performance Optimizations
- **Docker BuildKit** enabled for faster builds
- **Multi-stage builds** to reduce image sizes
- **Volume caching** for node_modules
- **WSL 2 integration** for better performance

## Troubleshooting

### Common Issues and Solutions

#### 1. Docker Desktop Not Starting
```powershell
# Check if WSL 2 is properly installed
wsl --list --verbose

# If WSL 2 is not default, set it:
wsl --set-default-version 2
```

#### 2. Port Already in Use
If ports 3000 or 4000 are occupied:
```powershell
# Check what's using the ports
netstat -ano | findstr :3000
netstat -ano | findstr :4000

# Kill the process if needed (replace PID with actual process ID)
taskkill /PID <PID> /F
```

#### 3. Permission Issues
Run PowerShell as Administrator:
```powershell
# Right-click PowerShell and select "Run as Administrator"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 4. Build Failures
If the build fails:
```powershell
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker-compose -f docker-compose.windows.yml build --no-cache
```

#### 5. API Key Issues
Verify your API key configuration:
```powershell
# Check config file
Get-Content config.ts | Select-String "apiKey"

# Test API connectivity (if using OpenRouter)
Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/models" -Headers @{"Authorization"="Bearer your-api-key"}
```

### Windows Firewall
If you encounter network issues:
1. Open Windows Defender Firewall
2. Allow Docker Desktop through the firewall
3. Ensure ports 3000 and 4000 are not blocked

### Antivirus Software
Some antivirus software may interfere with Docker:
- Add Docker Desktop to antivirus exclusions
- Add the project directory to exclusions
- Temporarily disable real-time scanning if issues persist

## File Structure (Windows-Specific)

```
december/
├── backend/                     # Backend API service
│   ├── src/                    # Source code
│   ├── Dockerfile              # Backend container config
│   └── package.json            # Dependencies
├── frontend/                   # Frontend Next.js app
│   ├── src/                    # Source code
│   ├── Dockerfile              # Frontend container config
│   └── package.json            # Dependencies
├── config.ts                   # Main configuration
├── docker-compose.yml          # Standard Docker Compose
├── docker-compose.windows.yml  # Windows-optimized config
├── start-windows.ps1           # PowerShell startup script
├── start-windows.bat           # Batch startup script
└── README-Windows11.md         # This file
```

## Development Workflow

### Making Changes
1. **Backend changes:** Edit files in `backend/src/`
2. **Frontend changes:** Edit files in `frontend/src/`
3. **Configuration:** Edit `config.ts`

### Restarting Services
```powershell
# Stop services
docker-compose -f docker-compose.windows.yml down

# Start with rebuild
docker-compose -f docker-compose.windows.yml up --build
```

### Viewing Logs
```powershell
# View all logs
docker-compose -f docker-compose.windows.yml logs

# View specific service logs
docker-compose -f docker-compose.windows.yml logs backend
docker-compose -f docker-compose.windows.yml logs frontend
```

### Accessing Container Shell
```powershell
# Backend container
docker-compose -f docker-compose.windows.yml exec backend bash

# Frontend container
docker-compose -f docker-compose.windows.yml exec frontend bash
```

## Performance Tips for Windows

### 1. WSL 2 Optimization
- Store project files in WSL 2 filesystem for better performance
- Use `\\wsl$\Ubuntu\home\username\december` path

### 2. Docker Desktop Settings
- **Resources > Memory:** Allocate at least 4GB to Docker
- **Resources > CPU:** Allocate at least 2 CPU cores
- **Docker Engine:** Enable experimental features

### 3. Windows-Specific Optimizations
- Disable Windows Search indexing on project directory
- Exclude project directory from Windows Defender real-time scanning
- Use SSD storage for better I/O performance

## Security Considerations

### API Key Management
- Never commit API keys to version control
- Use environment variables for production deployments
- Regularly rotate API keys

### Network Security
- December runs locally by default (localhost only)
- No external network access required except for AI API calls
- All data remains on your local machine

### Container Security
- Containers run with limited privileges
- No sensitive host directories are mounted
- Regular Docker security updates recommended

## Backup and Export

### Exporting Projects
December includes built-in export functionality:
1. Create your project in the web interface
2. Use the export feature to download as ZIP
3. Projects can be imported into other development environments

### Backing Up Configuration
```powershell
# Backup configuration
Copy-Item config.ts config.backup.ts

# Backup entire project
Copy-Item -Path . -Destination ../december-backup -Recurse
```

## Advanced Configuration

### Custom Ports
To use different ports, modify `docker-compose.windows.yml`:
```yaml
services:
  frontend:
    ports:
      - "8080:3000"  # Custom frontend port
  backend:
    ports:
      - "8081:4000"  # Custom backend port
```

### Resource Limits
Add resource constraints to services:
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
```

### Environment Variables
Create a `.env` file for custom environment variables:
```env
NODE_ENV=development
API_KEY=your-api-key-here
PORT=4000
```

## Support and Community

- **GitHub Issues:** https://github.com/ntegrals/december/issues
- **Discussions:** https://github.com/ntegrals/december/discussions
- **Documentation:** https://github.com/ntegrals/december

## License

December is distributed under the MIT License. See `LICENSE` for more information.

---

**Need Help?** 
- Check the troubleshooting section above
- Open an issue on GitHub with your specific problem
- Include your Windows version, Docker version, and error logs

**Happy Coding with December! 🎄**