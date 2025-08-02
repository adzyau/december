#!/bin/bash

echo "Starting December project with npm..."

# Check if node_modules exist, if not install dependencies
echo "Checking dependencies..."

if [ ! -d "backend/node_modules" ]; then
    echo "Installing backend dependencies..."
    cd backend && npm install && cd ..
fi

if [ ! -d "frontend/node_modules" ]; then
    echo "Installing frontend dependencies..."
    cd frontend && npm install && cd ..
fi

echo "Starting backend server..."

# Copy config file to backend directory
cp config.ts backend/config.ts
cd backend && npm run dev &
BACKEND_PID=$!

echo "Starting frontend server..."
cd ../frontend && npm run dev &
FRONTEND_PID=$!

echo "Both servers are starting..."
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo "Press Ctrl+C to stop both servers"

# Function to handle Ctrl+C
cleanup() {
    echo -e "\nStopping servers..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    exit 0
}

# Set up trap to catch Ctrl+C
trap cleanup INT

# Wait for both processes
wait