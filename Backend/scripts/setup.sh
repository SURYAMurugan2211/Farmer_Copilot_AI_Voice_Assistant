#!/bin/bash

# Farmer Copilot Setup Script
# This script sets up the development environment

set -e

echo "🌾 Setting up Farmer Copilot Development Environment"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Python version
print_status "Checking Python version..."
if command -v python3.11 &> /dev/null; then
    PYTHON_CMD="python3.11"
elif command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [[ "$PYTHON_VERSION" == "3.11" ]] || [[ "$PYTHON_VERSION" == "3.10" ]] || [[ "$PYTHON_VERSION" == "3.9" ]]; then
        PYTHON_CMD="python3"
    else
        print_error "Python 3.9+ required. Found: $PYTHON_VERSION"
        exit 1
    fi
else
    print_error "Python 3.9+ not found. Please install Python first."
    exit 1
fi

print_status "Using Python: $($PYTHON_CMD --version)"

# Create virtual environment
print_status "Creating virtual environment..."
if [ ! -d "venv" ]; then
    $PYTHON_CMD -m venv venv
    print_status "Virtual environment created"
else
    print_warning "Virtual environment already exists"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate || source venv/Scripts/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
print_status "Installing Python dependencies..."
pip install -r requirements.txt

# Create necessary directories
print_status "Creating storage directories..."
mkdir -p storage/{audio,documents,cache,logs,temp,reports,fallback_knowledge}
mkdir -p backups

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file..."
    cp .env.example .env
    print_warning "Please update .env file with your configuration"
else
    print_warning ".env file already exists"
fi

# Initialize database
print_status "Initializing database..."
$PYTHON_CMD -c "
from services.db.session import create_tables
create_tables()
print('Database initialized successfully')
"

# Download models (optional)
print_status "Checking AI models..."
print_warning "AI models will be downloaded on first use"
print_warning "This may take several minutes depending on your internet connection"

# Test installation
print_status "Testing installation..."
$PYTHON_CMD -c "
import sys
sys.path.append('.')
try:
    from services.api.app import app
    print('✅ FastAPI app imports successfully')
except Exception as e:
    print(f'❌ Import error: {e}')
    sys.exit(1)
"

# Create sample documents
print_status "Creating sample agricultural documents..."
cat > storage/documents/sample_farming_guide.txt << 'EOF'
# Basic Farming Guide

## Soil Preparation
Good soil is the foundation of successful farming. Test your soil pH and ensure it's between 6.0-7.0 for most crops.

## Crop Rotation
Rotate crops annually to maintain soil health and reduce pest problems. Follow legumes with heavy feeders like corn.

## Watering
Water deeply but less frequently to encourage deep root growth. Early morning is the best time to water.

## Pest Management
Use integrated pest management (IPM) combining biological, cultural, and chemical controls when necessary.
EOF

print_status "Sample document created"

# Set up Git hooks (if in a git repository)
if [ -d ".git" ]; then
    print_status "Setting up Git hooks..."
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run basic checks before commit
echo "Running pre-commit checks..."

# Check Python syntax
python -m py_compile services/api/app.py
if [ $? -ne 0 ]; then
    echo "Python syntax error found!"
    exit 1
fi

echo "Pre-commit checks passed!"
EOF
    chmod +x .git/hooks/pre-commit
    print_status "Git hooks configured"
fi

# Display setup summary
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Activate virtual environment: source venv/bin/activate (Linux/Mac) or venv\\Scripts\\activate (Windows)"
echo "2. Update .env file with your configuration"
echo "3. Start the development server: python -m uvicorn services.api.app:app --reload"
echo "4. Visit http://localhost:8000/docs for API documentation"
echo ""
echo "For production deployment, see PRODUCTION_DEPLOYMENT.md"
echo ""
echo -e "${GREEN}🌾 Happy farming! 👨‍🌾${NC}"