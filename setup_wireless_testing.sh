#!/bin/bash

# Allma Wireless Device Testing Setup
# This script helps set up wireless debugging for physical devices

echo "📱 Allma Wireless Testing Setup"
echo "==============================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up wireless debugging...${NC}"
echo ""

echo -e "${YELLOW}📱 iOS Wireless Testing Setup:${NC}"
echo "1. Connect iPhone via USB initially"
echo "2. In Xcode: Window → Devices and Simulators"
echo "3. Select your device → Check 'Connect via network'"
echo "4. Once connected wirelessly, unplug USB"
echo "5. Device should appear with network icon in flutter devices"
echo ""

echo -e "${YELLOW}🤖 Android Wireless Testing Setup:${NC}"
echo "1. Enable Developer Options and USB Debugging"
echo "2. Connect via USB initially"
echo "3. Run: adb tcpip 5555"
echo "4. Find device IP: Settings → About Phone → Status → IP Address"
echo "5. Run: adb connect <device-ip>:5555"
echo "6. Unplug USB cable"
echo ""

echo -e "${BLUE}Checking current device connections...${NC}"
flutter devices
echo ""

# Check for ADB (Android Debug Bridge)
if command -v adb >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ADB found${NC}"
    echo "Current ADB devices:"
    adb devices
else
    echo -e "${YELLOW}⚠️  ADB not found. Install Android Studio for full Android support${NC}"
fi

echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo "• Check devices: ${GREEN}flutter devices${NC}"
echo "• ADB wireless: ${GREEN}adb tcpip 5555 && adb connect <ip>:5555${NC}"
echo "• Run on device: ${GREEN}flutter run -d <device-id>${NC}"
echo "• Hot reload: Press 'r' in Flutter"
echo "• Hot restart: Press 'R' in Flutter"