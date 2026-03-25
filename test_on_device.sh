#!/bin/bash

# Allma Device Testing Script
# This script helps you test the Allma app on physical devices

echo "🚀 Allma Device Testing Helper"
echo "=============================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${BLUE}Step 1: Checking Flutter setup...${NC}"
if ! command_exists flutter; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"
flutter --version | head -1

echo ""
echo -e "${BLUE}Step 2: Checking connected devices...${NC}"
flutter devices

echo ""
echo -e "${BLUE}Step 3: Available testing options:${NC}"
echo ""
echo "📱 ${YELLOW}FOR iOS DEVICE TESTING:${NC}"
echo "   1. Connect your iPhone via USB cable"
echo "   2. Enable Developer Mode:"
echo "      Settings → Privacy & Security → Developer Mode → ON"
echo "   3. Trust this computer when prompted"
echo "   4. Run: ${GREEN}flutter run -d <device-id>${NC}"
echo ""
echo "🤖 ${YELLOW}FOR ANDROID DEVICE TESTING:${NC}"
echo "   1. Enable Developer Options:"
echo "      Settings → About Phone → Tap 'Build Number' 7 times"
echo "   2. Enable USB Debugging:"
echo "      Settings → Developer Options → USB Debugging → ON"
echo "   3. Connect via USB and allow debugging"
echo "   4. Run: ${GREEN}flutter run -d <device-id>${NC}"
echo ""
echo "💻 ${YELLOW}FOR SIMULATOR/EMULATOR:${NC}"
echo "   • iOS Simulator: Need Xcode installed"
echo "   • Android Emulator: Need Android Studio with AVD"
echo ""

# Check if any physical devices are connected
devices_output=$(flutter devices 2>/dev/null)
if echo "$devices_output" | grep -q "No devices"; then
    echo -e "${YELLOW}⚠️  No physical devices detected${NC}"
    echo ""
    echo -e "${BLUE}To connect your device:${NC}"
    echo ""
    echo -e "${YELLOW}📱 iOS Device Setup:${NC}"
    echo "1. Connect iPhone via USB"
    echo "2. Settings → Privacy & Security → Developer Mode → Enable"
    echo "3. Trust computer when prompted"
    echo "4. Run this script again"
    echo ""
    echo -e "${YELLOW}🤖 Android Device Setup:${NC}"
    echo "1. Settings → About Phone → Tap 'Build Number' 7x"
    echo "2. Settings → Developer Options → USB Debugging → Enable"
    echo "3. Connect via USB, allow debugging"
    echo "4. Run this script again"
    echo ""
else
    echo -e "${GREEN}✅ Devices detected!${NC}"
    echo ""
    echo -e "${BLUE}Choose a device to run Allma:${NC}"
    
    # Extract device information - only the actual device lines
    device_lines=$(echo "$devices_output" | grep -E "•" | grep -v "No devices\|No wireless")
    
    if [ ! -z "$device_lines" ]; then
        echo "$device_lines" | nl -w2 -s'. '
        echo ""
        read -p "Enter device number (or 'q' to quit): " choice
        
        if [ "$choice" = "q" ]; then
            echo "Exiting..."
            exit 0
        fi
        
        # Get the selected device line
        selected_line=$(echo "$device_lines" | sed -n "${choice}p")
        if [ ! -z "$selected_line" ]; then
            # Extract device ID (between the • symbols, second field)
            device_id=$(echo "$selected_line" | awk '{print $4}')
            device_name=$(echo "$selected_line" | awk '{print $1}')
            
            echo ""
            echo -e "${GREEN}🚀 Starting Allma on $device_name ($device_id)...${NC}"
            echo ""
            echo -e "${YELLOW}Development Commands:${NC}"
            echo "• Hot reload: Press 'r'"
            echo "• Hot restart: Press 'R'"
            echo "• Quit: Press 'q'"
            echo ""
            
            # Run Flutter on selected device
            flutter run -d "$device_id"
        else
            echo -e "${RED}❌ Invalid selection${NC}"
            exit 1
        fi
    fi
fi

echo ""
echo -e "${BLUE}Additional Resources:${NC}"
echo "• Flutter Doctor: ${GREEN}flutter doctor${NC}"
echo "• Device List: ${GREEN}flutter devices${NC}"
echo "• iOS Setup: https://docs.flutter.dev/platform-integration/ios/setup"
echo "• Android Setup: https://docs.flutter.dev/platform-integration/android/setup"