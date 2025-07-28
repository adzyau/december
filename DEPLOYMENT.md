# December AI Platform - VPS Deployment Guide

This guide will help you deploy the December AI Platform to your VPS using Docker.

## Prerequisites

- A VPS running Ubuntu 20.04+ (or compatible Linux distribution)
- SSH access to your VPS
- A user account with sudo privileges
- At least 2GB RAM and 20GB storage
- An API key from an OpenAI-compatible provider (OpenAI, Anthropic, OpenRouter, etc.)

## Quick Start

1. **Clone the repository on your VPS:**
   ```bash
   git clone https://github.com/ntegrals/december.git
   cd december
   ```

2. **Configure your API settings:**
   Edit the `config.ts` file with your API credentials:
   ```typescript
   export const config = {
     aiSdk: {
       baseUrl: "https://openrouter.ai/api/v1",  // Or your provider's URL
       apiKey: "your-api-key-here",
       model: "anthropic/claude-sonnet-4",       // Recommended model
     },
   } as const;
   ```

3. **Run the deployment script:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh install
   ```

4. **Access your application:**
   - Frontend: `http://your-vps-ip`
   - Direct Frontend: `http://your-vps-ip:3000`
   - Backend API: `http://your-vps-ip:4000`

## Detailed Installation Steps

### Step 1: Prepare Your VPS

Connect to your VPS via SSH:
```bash
ssh your-username@your-vps-ip
```

Update your system:
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Clone and Configure

Clone the December repository:
```bash
git clone https://github.com/ntegrals/december.git
cd december
```

Configure your API settings by editing `config.ts`:
```bash
nano config.ts
```

### Step 3: Deploy

Make the deployment script executable and run it:
```bash
chmod +x deploy.sh
./deploy.sh install
```

The script will:
- Install Docker and Docker Compose
- Set up firewall rules
- Create system services
- Build and deploy the application
- Configure Nginx reverse proxy

## Architecture Overview

The deployment includes:

- **December App Container**: Runs both frontend (Next.js) and backend (Express.js)
- **Nginx Container**: Reverse proxy and load balancer
- **Docker Network**: Isolated network for container communication

## Configuration Files

### Dockerfile
Multi-stage build that:
1. Builds the Next.js frontend
2. Prepares the backend
3. Creates a production image with both services

### docker-compose.yml
Orchestrates the services:
- December application container
- Nginx reverse proxy
- Shared network and volumes

### nginx.conf
Nginx configuration with:
- Reverse proxy to frontend and backend
- Rate limiting
- Security headers
- SSL support (when configured)

## Management Commands

The deployment script provides several management commands:

```bash
# View status
./deploy.sh status

# View logs
./deploy.sh logs

# Update application
./deploy.sh update

# Start/stop/restart
./deploy.sh start
./deploy.sh stop
./deploy.sh restart
```

## System Service Management

December is installed as a systemd service:

```bash
# Check service status
sudo systemctl status december

# Start/stop/restart service
sudo systemctl start december
sudo systemctl stop december
sudo systemctl restart december

# View service logs
sudo journalctl -u december -f
```

## SSL/HTTPS Setup (Optional)

To enable HTTPS:

1. **Get SSL certificates** (using Let's Encrypt):
   ```bash
   sudo apt install certbot
   sudo certbot certonly --standalone -d your-domain.com
   ```

2. **Create SSL directory and copy certificates:**
   ```bash
   sudo mkdir -p /opt/december/ssl
   sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/december/ssl/cert.pem
   sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /opt/december/ssl/key.pem
   sudo chown -R $USER:$USER /opt/december/ssl
   ```

3. **Update nginx.conf** to uncomment the HTTPS server block and update the domain name.

4. **Restart the services:**
   ```bash
   cd /opt/december
   docker-compose restart nginx
   ```

## Firewall Configuration

The deployment script configures UFW with these rules:
- SSH (port 22): Allowed
- HTTP (port 80): Allowed
- HTTPS (port 443): Allowed
- December Frontend (port 3000): Allowed
- December Backend (port 4000): Allowed

To modify firewall rules:
```bash
sudo ufw status
sudo ufw allow/deny [port]/tcp
```

## Troubleshooting

### Check Container Status
```bash
cd /opt/december
docker-compose ps
```

### View Container Logs
```bash
cd /opt/december
docker-compose logs -f december  # Application logs
docker-compose logs -f nginx     # Nginx logs
```

### Check System Resources
```bash
docker system df
docker stats
```

### Restart Everything
```bash
cd /opt/december
docker-compose down
docker-compose up -d
```

### Clean Up Docker
```bash
docker system prune -a
docker volume prune
```

## Performance Optimization

### For Production Use:

1. **Increase system limits** in `/etc/security/limits.conf`:
   ```
   * soft nofile 65536
   * hard nofile 65536
   ```

2. **Optimize Docker daemon** in `/etc/docker/daemon.json`:
   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   ```

3. **Monitor resources:**
   ```bash
   htop
   docker stats
   ```

## Backup and Updates

### Backup Configuration
```bash
# Backup your config and any custom changes
tar -czf december-backup-$(date +%Y%m%d).tar.gz /opt/december/config.ts
```

### Update Application
```bash
cd /opt/december
git pull
./deploy.sh update
```

## Security Considerations

1. **Change default ports** if needed
2. **Use strong API keys** and keep them secure
3. **Regular system updates**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
4. **Monitor logs** for suspicious activity
5. **Use HTTPS** in production
6. **Limit SSH access** to specific IPs if possible

## Support

If you encounter issues:

1. Check the logs: `./deploy.sh logs`
2. Verify configuration: `./deploy.sh status`
3. Restart services: `./deploy.sh restart`
4. Check system resources: `htop` and `df -h`

For additional help, refer to the main README.md or open an issue on GitHub.

## Uninstalling

To completely remove December:

```bash
# Stop and remove containers
cd /opt/december
docker-compose down -v

# Remove systemd service
sudo systemctl stop december
sudo systemctl disable december
sudo rm /etc/systemd/system/december.service
sudo systemctl daemon-reload

# Remove application directory
sudo rm -rf /opt/december

# Remove Docker images (optional)
docker rmi $(docker images | grep december | awk '{print $3}')

# Remove Docker completely (optional)
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```