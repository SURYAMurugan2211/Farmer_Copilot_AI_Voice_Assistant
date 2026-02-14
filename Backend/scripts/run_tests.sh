#!/bin/bash

# Farmer Copilot Test Suite Runner
# Usage: ./scripts/run_tests.sh [test_type]
# Test types: unit, integration, performance, all

set -e

TEST_TYPE=${1:-all}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="storage/reports/tests"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Create report directory
mkdir -p $REPORT_DIR

print_header "Farmer Copilot Test Suite"
print_status "Test type: $TEST_TYPE"
print_status "Report directory: $REPORT_DIR"

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
else
    print_warning "Virtual environment not found. Using system Python."
fi

# Function to run unit tests
run_unit_tests() {
    print_header "Running Unit Tests"
    
    # Install test dependencies
    pip install pytest pytest-cov pytest-asyncio httpx

    # Run tests with coverage
    python -m pytest tests/ \
        --cov=services \
        --cov-report=html:$REPORT_DIR/coverage_$TIMESTAMP \
        --cov-report=term \
        --junit-xml=$REPORT_DIR/junit_$TIMESTAMP.xml \
        -v
    
    print_status "Unit tests completed. Coverage report: $REPORT_DIR/coverage_$TIMESTAMP"
}

# Function to run integration tests
run_integration_tests() {
    print_header "Running Integration Tests"
    
    # Start test server
    print_status "Starting test server..."
    python -m uvicorn services.api.app:app --host 127.0.0.1 --port 8001 &
    SERVER_PID=$!
    
    # Wait for server to start
    sleep 10
    
    # Test API endpoints
    print_status "Testing API endpoints..."
    
    # Health check
    if curl -f http://127.0.0.1:8001/health > /dev/null 2>&1; then
        print_status "✅ Health check passed"
    else
        print_error "❌ Health check failed"
    fi
    
    # Test mobile endpoints
    if curl -f http://127.0.0.1:8001/api/mobile/health-mobile > /dev/null 2>&1; then
        print_status "✅ Mobile health check passed"
    else
        print_error "❌ Mobile health check failed"
    fi
    
    # Test text query
    RESPONSE=$(curl -s -X POST http://127.0.0.1:8001/api/mobile/text-query \
        -H "Content-Type: application/json" \
        -d '{"text": "What is farming?", "lang": "en"}')
    
    if echo "$RESPONSE" | grep -q "success"; then
        print_status "✅ Text query test passed"
    else
        print_error "❌ Text query test failed"
        echo "Response: $RESPONSE"
    fi
    
    # Stop test server
    kill $SERVER_PID
    wait $SERVER_PID 2>/dev/null || true
    
    print_status "Integration tests completed"
}

# Function to run performance tests
run_performance_tests() {
    print_header "Running Performance Tests"
    
    # Install performance testing tools
    pip install locust

    # Start server for performance testing
    print_status "Starting server for performance testing..."
    python -m uvicorn services.api.app:app --host 127.0.0.1 --port 8002 &
    SERVER_PID=$!
    
    # Wait for server to start
    sleep 15
    
    # Create Locust test file
    cat > /tmp/locustfile.py << 'EOF'
from locust import HttpUser, task, between
import json

class FarmerCopilotUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Register a test user
        response = self.client.post("/api/users/register", json={
            "phone_number": f"+123456789{self.environment.parsed_options.num_users}",
            "name": "Test Farmer",
            "language": "en"
        })
        if response.status_code == 200:
            self.user_id = response.json()["id"]
        else:
            self.user_id = None
    
    @task(3)
    def text_query(self):
        self.client.post("/api/mobile/text-query", json={
            "text": "How do I grow tomatoes?",
            "lang": "en",
            "user_id": self.user_id
        })
    
    @task(1)
    def health_check(self):
        self.client.get("/health")
    
    @task(1)
    def get_languages(self):
        self.client.get("/api/mobile/languages")
EOF

    # Run performance test
    print_status "Running performance test with 10 users..."
    locust -f /tmp/locustfile.py --host=http://127.0.0.1:8002 \
        --users 10 --spawn-rate 2 --run-time 60s --headless \
        --html $REPORT_DIR/performance_$TIMESTAMP.html
    
    # Stop server
    kill $SERVER_PID
    wait $SERVER_PID 2>/dev/null || true
    
    print_status "Performance tests completed. Report: $REPORT_DIR/performance_$TIMESTAMP.html"
}

# Function to run all tests
run_all_tests() {
    print_header "Running Complete Test Suite"
    run_unit_tests
    run_integration_tests
    run_performance_tests
    
    # Generate summary report
    cat > $REPORT_DIR/test_summary_$TIMESTAMP.md << EOF
# Test Summary Report - $TIMESTAMP

## Test Results

### Unit Tests
- Coverage report: coverage_$TIMESTAMP/
- JUnit report: junit_$TIMESTAMP.xml

### Integration Tests
- API endpoint tests completed
- Health checks verified

### Performance Tests
- Load test report: performance_$TIMESTAMP.html
- 10 concurrent users for 60 seconds

## Recommendations

1. Review coverage report for areas needing more tests
2. Monitor performance metrics in production
3. Set up continuous integration for automated testing

Generated on: $(date)
EOF

    print_status "Complete test suite finished!"
    print_status "Summary report: $REPORT_DIR/test_summary_$TIMESTAMP.md"
}

# Main execution
case $TEST_TYPE in
    "unit")
        run_unit_tests
        ;;
    "integration")
        run_integration_tests
        ;;
    "performance")
        run_performance_tests
        ;;
    "all")
        run_all_tests
        ;;
    *)
        print_error "Invalid test type: $TEST_TYPE"
        print_error "Valid options: unit, integration, performance, all"
        exit 1
        ;;
esac

print_status "🎉 Testing completed successfully!"