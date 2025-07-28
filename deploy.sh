#!/bin/bash

# December AI Platform - VPS Deployment Script
# This script sets up Docker and deploys the December application on a VPS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="december"
APP_DIR="/opt/december"
DOCKER_COMPOSE_VERSION="2.24.1"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons."
        log_info "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges."
        log_info "Please ensure your user has sudo access."
        exit 1
    fi
}

install_docker() {
    log_info "Installing Docker..."
    
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up stable repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    log_success "Docker installed successfully!"
}

install_docker_compose() {
    log_info "Installing Docker Compose..."
    
    # Download and install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for docker-compose command
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose installed successfully!"
}

setup_firewall() {
    log_info "Configuring firewall..."
    
    # Install ufw if not present
    sudo apt-get install -y ufw
    
    # Reset firewall rules
    sudo ufw --force reset
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (be careful with this!)
    sudo ufw allow ssh
    sudo ufw allow 22/tcp
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow Docker ports (optional, for direct access during development)
    sudo ufw allow 3000/tcp comment "December Frontend"
    sudo ufw allow 4000/tcp comment "December Backend"
    
    # Enable firewall
    sudo ufw --force enable
    
    log_success "Firewall configured successfully!"
}

create_app_directory() {
    log_info "Creating application directory..."
    
    sudo mkdir -p $APP_DIR
    sudo chown $USER:$USER $APP_DIR
    
    log_success "Application directory created at $APP_DIR"
}

setup_systemd_service() {
    log_info "Setting up systemd service..."
    
    sudo tee /etc/systemd/system/december.service > /dev/null <<EOF
[Unit]
Description=December AI Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
ExecReload=/usr/local/bin/docker-compose restart
User=$USER
Group=docker

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable december.service
    
    log_success "Systemd service created and enabled!"
}

setup_log_rotation() {
    log_info "Setting up log rotation..."
    
    sudo tee /etc/logrotate.d/december > /dev/null <<EOF
/var/lib/docker/containers/*/*-json.log {
    daily
    rotate 7
    compress
    size 10M
    missingok
    delaycompress
    copytruncate
}
EOF
    
    log_success "Log rotation configured!"
}

check_config() {
    log_info "Checking configuration..."
    
    if [[ ! -f "config.ts" ]]; then
        log_error "config.ts file not found!"
        log_info "Please create a config.ts file with your API configuration."
        log_info "Example:"
        echo "export const config = {"
        echo "  aiSdk: {"
        echo "    baseUrl: \"https://openrouter.ai/api/v1\","
        echo "    apiKey: \"your-api-key-here\","
        echo "    model: \"anthropic/claude-sonnet-4\","
        echo "  },"
        echo "} as const;"
        exit 1
    fi
    
    log_success "Configuration file found!"
}

deploy_application() {
    log_info "Deploying December application..."
    
    # Copy application files
    cp -r . $APP_DIR/
    cd $APP_DIR
    
    # Build and start the application
    log_info "Building Docker images..."
    docker-compose build --no-cache
    
    log_info "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to start..."
    sleep 30
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        log_success "December application deployed successfully!"
        log_info "Frontend: http://$(curl -s ifconfig.me):3000"
        log_info "Backend API: http://$(curl -s ifconfig.me):4000"
        log_info "Nginx Proxy: http://$(curl -s ifconfig.me)"
    else
        log_error "Failed to start services. Check logs with: docker-compose logs"
        exit 1
    fi
}

show_status() {
    log_info "Service Status:"
    docker-compose ps
    
    log_info "\nDocker Images:"
    docker images | grep december
    
    log_info "\nSystem Resources:"
    docker system df
    
    log_info "\nUseful Commands:"
    echo "  View logs: docker-compose logs -f"
    echo "  Restart: docker-compose restart"
    echo "  Stop: docker-compose down"
    echo "  Update: git pull && docker-compose build --no-cache && docker-compose up -d"
    echo "  System service: sudo systemctl status december"
}

main() {
    echo "=========================================="
    echo "December AI Platform - VPS Deployment"
    echo "=========================================="
    
    # Pre-flight checks
    check_root
    check_sudo
    check_config
    
    # System setup
    log_info "Starting deployment process..."
    
    # Update system
    log_info "Updating system packages..."
    sudo apt-get update && sudo apt-get upgrade -y
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        install_docker
        install_docker_compose
        log_warning "Docker was just installed. Please log out and log back in, then run this script again."
        exit 0
    else
        log_success "Docker is already installed!"
    fi
    
    # Setup system components
    setup_firewall
    create_app_directory
    setup_systemd_service
    setup_log_rotation
    
    # Deploy application
    deploy_application
    
    # Show status
    show_status
    
    log_success "Deployment completed successfully!"
    log_info "December AI Platform is now running on your VPS!"
    
    echo ""
    echo "=========================================="
    echo "🎉 December is ready to use!"
    echo "=========================================="
    echo "Frontend: http://$(curl -s ifconfig.me)"
    echo "Direct Frontend: http://$(curl -s ifconfig.me):3000"
    echo "Backend API: http://$(curl -s ifconfig.me):4000"
    echo ""
    echo "To manage the service:"
    echo "  sudo systemctl start december"
    echo "  sudo systemctl stop december"
    echo "  sudo systemctl restart december"
    echo "  sudo systemctl status december"
    echo ""
    echo "To view logs:"
    echo "  cd $APP_DIR && docker-compose logs -f"
    echo "=========================================="
}

# Handle script arguments
case "${1:-}" in
    "install")
        main
        ;;
    "update")
        log_info "Updating December application..."
        cd $APP_DIR
        git pull
        docker-compose build --no-cache
        docker-compose up -d
        show_status
        ;;
    "status")
        cd $APP_DIR
        show_status
        ;;
    "logs")
        cd $APP_DIR
        docker-compose logs -f
        ;;
    "stop")
        cd $APP_DIR
        docker-compose down
        log_success "December stopped!"
        ;;
    "start")
        cd $APP_DIR
        docker-compose up -d
        log_success "December started!"
        ;;
    "restart")
        cd $APP_DIR
        docker-compose restart
        log_success "December restarted!"
        ;;
    *)
        echo "Usage: $0 {install|update|status|logs|stop|start|restart}"
        echo ""
        echo "Commands:"
        echo "  install  - Full installation and deployment"
        echo "  update   - Update application and restart"
        echo "  status   - Show service status"
        echo "  logs     - Show application logs"
        echo "  stop     - Stop the application"
        echo "  start    - Start the application"
        echo "  restart  - Restart the application"
        exit 1
        ;;
esac