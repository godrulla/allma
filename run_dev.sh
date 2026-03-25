#!/bin/bash

# Quick development server startup script for Allma

echo "🚀 Starting Allma Development Server..."
echo ""

# Check if Flutter is in PATH
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please run ./setup_and_run.sh first to install Flutter"
    exit 1
fi

# Navigate to project directory
cd /Users/mando/Desktop/Allma

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "🔍 Available devices:"
flutter devices

echo ""
echo "Select how to run Allma:"
echo "1. Web Browser (Chrome) - Recommended for quick testing"
echo "2. iOS Simulator"
echo "3. Android Emulator"
echo "4. Physical Device"

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🌐 Starting on Web Browser..."
        echo "Opening at http://localhost:8080"
        flutter run -d chrome --web-port=8080
        ;;
    2)
        echo ""
        echo "📱 Starting on iOS Simulator..."
        open -a Simulator 2>/dev/null
        sleep 3
        flutter run -d iphone
        ;;
    3)
        echo ""
        echo "🤖 Starting on Android Emulator..."
        flutter run -d android
        ;;
    4)
        echo ""
        echo "📲 Starting on Physical Device..."
        flutter run
        ;;
    *)
        echo "Invalid choice, starting on Chrome by default..."
        flutter run -d chrome --web-port=8080
        ;;
esac