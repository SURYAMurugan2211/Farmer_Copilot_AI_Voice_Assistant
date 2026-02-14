#!/bin/bash

# Farmer Copilot Deployment Script
# Usage: ./scripts/deploy.sh [environment]
# Environments: dev, staging, prod

set -e

ENVIRONMENT=${1:-dev}
PROJECT_NAME="farmer-copilot"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🚀 Starting deployment for environment: $ENVIRONMENT"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Environment-specific configurations
case $ENVIRONMENT in
    "dev")
        COMPOSE_FILE="docker-compose.yml"
        DATABASE_URL="sqlite:///./farmer_copilot.db"
        ;;
    "staging")
        COMPOSE_FILE="docker-compose.staging.yml"
        DATABASE_URL="postgresql://farmer_user:staging_password@postgres:5432/farmer_copilot_staging"
        ;;
    "prod")
        COMPOSE_FILE="docker-compose.prod.yml"
        DATABASE_URL="postgresql://farmer_user:${DB_PASSWORD}@postgres:5432/farmer_copilot"
        ;;
    *)
        print_error "Invalid environment: $ENVIRONMENT. Use: dev, staging, or prod"
        exit 1
        ;;
esac

print_status "Deploying to $ENVIRONMENT environment using $COMPOSE_FILE"

# Create backup if production
if [ "$ENVIRONMENT" = "prod" ]; then
    print_status "Creating backup before deployment..."
    mkdir -p backups
    
    # Backup database
    if [ -f "farmer_copilot.db" ]; then
        cp farmer_copilot.db "backups/farmer_copilot_backup_$TIMESTAMP.db"
        print_status "Database backup created: backups/farmer_copilot_backup_$TIMESTAMP.db"
    fi
    
    # Backup storage
    if [ -d "storage" ]; then
        tar -czf "backups/storage_backup_$TIMESTAMP.tar.gz" storage/
        print_status "Storage backup created: backups/storage_backup_$TIMESTAMP.tar.gz"
    fi
fi

# Pull latest images
print_status "Pulling latest Docker images..."
docker-compose -f $COMPOSE_FILE pull

# Build application
print_status "Building application..."
docker-compose -f $COMPOSE_FILE build --no-cache

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose -f $COMPOSE_FILE down

# Start services
print_status "Starting services..."
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Health check
print_status "Performing health check..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        print_status "✅ Health check passed!"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        print_warning "Health check failed. Retry $RETRY_COUNT/$MAX_RETRIES..."
        sleep 10
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    print_error "❌ Health check failed after $MAX_RETRIES attempts"
    print_error "Deployment may have issues. Check logs with: docker-compose -f $COMPOSE_FILE logs"
    exit 1
fi

# Show running containers
print_status "Running containers:"
docker-compose -f $COMPOSE_FILE ps

# Show logs
print_status "Recent logs:"
docker-compose -f $COMPOSE_FILE logs --tail=20

print_status "🎉 Deployment completed successfully!"
print_status "API is available at: http://localhost:8000"
print_status "Documentation: http://localhost:8000/docs"

# Environment-specific post-deployment tasks
if [ "$ENVIRONMENT" = "prod" ]; then
    print_status "Production deployment completed. Remember to:"
    print_status "1. Update DNS records if needed"
    print_status "2. Verify SSL certificates"
    print_status "3. Monitor application logs"
    print_status "4. Run smoke tests"
fi

echo -e "${GREEN}🌾 Farmer Copilot is ready to help farmers! 👨‍🌾${NC}"