# Windows PowerShell Setup & Troubleshooting

## 🚨 PowerShell Script Execution Error Fix

If you're getting this error:
```
.\start-windows.ps1 : The term '.\start-windows.ps1' is not recognized...
```

Follow these steps to resolve it:

### Step 1: Check PowerShell Execution Policy

1. **Open PowerShell as Administrator**:
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Check current execution policy**:
   ```powershell
   Get-ExecutionPolicy
   ```

3. **If it shows "Restricted", change it**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
   - Type `Y` when prompted

### Step 2: Navigate to Project Directory

Make sure you're in the correct directory:

```powershell
# Navigate to your December project folder
cd C:\Users\PC\Documents\GitHub\december

# Verify you're in the right place
ls *.ps1
```

You should see `start-windows.ps1` listed.

### Step 3: Run the Script

Now try running the script again:

```powershell
.\start-windows.ps1
```

## Alternative Solutions

### Option A: Run with Bypass Policy (One-time)
```powershell
PowerShell -ExecutionPolicy Bypass -File .\start-windows.ps1
```

### Option B: Use the Batch Script Instead
```cmd
start-windows.bat
```

### Option C: Manual Docker Compose
```powershell
docker-compose -f docker-compose.windows.yml up --build
```

## Step-by-Step Manual Setup

If scripts still don't work, run these commands manually:

### 1. Check Docker is Running
```powershell
docker --version
docker info
```

### 2. Copy Configuration
```powershell
copy config.ts backend\config.ts
```

### 3. Start Services
```powershell
docker-compose -f docker-compose.windows.yml up --build
```

### 4. Access Application
- Frontend: http://localhost:3000
- Backend: http://localhost:4000

## Common Issues & Solutions

### Issue: "docker: command not found"
**Solution**: Install Docker Desktop for Windows
- Download from: https://www.docker.com/products/docker-desktop/
- Restart your computer after installation

### Issue: "Access denied" or permission errors
**Solution**: 
1. Run PowerShell as Administrator
2. Add your user to the docker-users group:
   ```powershell
   net localgroup docker-users "your-username" /add
   ```
3. Log out and log back in

### Issue: WSL 2 not installed
**Solution**:
```powershell
# Install WSL 2
wsl --install

# Set WSL 2 as default
wsl --set-default-version 2
```

### Issue: API key not configured
**Solution**: Edit `config.ts` and replace the API key:
```typescript
export const config = {
  aiSdk: {
    baseUrl: "https://openrouter.ai/api/v1",
    apiKey: "your-actual-api-key-here", // Replace this
    model: "anthropic/claude-sonnet-4",
  },
} as const;
```

## Verification Steps

### 1. Check Services are Running
```powershell
docker-compose -f docker-compose.windows.yml ps
```

Should show:
```
NAME                   STATUS          PORTS
workspace-backend-1    Up              0.0.0.0:4000->4000/tcp
workspace-frontend-1   Up              0.0.0.0:3000->3000/tcp
```

### 2. Test Backend API
```powershell
curl http://localhost:4000/containers
```

### 3. Test Frontend
Open browser and go to: http://localhost:3000

## If All Else Fails

### Clean Start
```powershell
# Stop all containers
docker-compose -f docker-compose.windows.yml down

# Clean Docker system
docker system prune -a

# Rebuild everything
docker-compose -f docker-compose.windows.yml up --build
```

### Get Help
If you're still having issues:

1. **Check logs**:
   ```powershell
   docker-compose -f docker-compose.windows.yml logs
   ```

2. **Check Windows version**:
   ```powershell
   winver
   ```

3. **Verify Docker Desktop is running**:
   - Look for Docker Desktop icon in system tray
   - Should show "Docker Desktop is running"

## Quick Copy-Paste Commands

For fastest setup, copy and paste these commands one by one:

```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Navigate to project (adjust path as needed)
cd C:\Users\PC\Documents\GitHub\december

# Copy config
copy config.ts backend\config.ts

# Start December
docker-compose -f docker-compose.windows.yml up --build
```

---

**Need more help?** Check the main `README-Windows11.md` for comprehensive troubleshooting, or open an issue on GitHub with your specific error message and Windows version.