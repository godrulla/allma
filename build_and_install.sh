#!/bin/bash

# Allma Build and Install Script
# Builds and installs the app directly to connected devices

echo "🔨 Allma Build & Install"
echo "========================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if Flutter is installed
if ! command -v flutter >/dev/null 2>&1; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Cleaning previous builds...${NC}"
flutter clean
echo ""

echo -e "${BLUE}Step 2: Getting dependencies...${NC}"
flutter pub get
echo ""

echo -e "${BLUE}Step 3: Checking connected devices...${NC}"
devices_output=$(flutter devices 2>/dev/null)
echo "$devices_output"

if echo "$devices_output" | grep -q "No devices"; then
    echo ""
    echo -e "${YELLOW}⚠️  No devices connected. Please connect a device and try again.${NC}"
    echo ""
    echo -e "${BLUE}Device Setup Instructions:${NC}"
    echo "1. Run: ${GREEN}./setup_wireless_testing.sh${NC} for wireless setup"
    echo "2. Or connect via USB and enable debugging"
    echo "3. Then run this script again"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 4: Choose build type:${NC}"
echo "1. Debug build (faster, for testing)"
echo "2. Profile build (optimized, for performance testing)"
echo "3. Release build (production ready)"
echo ""
read -p "Enter choice (1-3): " build_type

case $build_type in
    1)
        echo -e "${BLUE}Building debug version...${NC}"
        flutter build apk --debug
        build_file="build/app/outputs/flutter-apk/app-debug.apk"
        ;;
    2)
        echo -e "${BLUE}Building profile version...${NC}"
        flutter build apk --profile
        build_file="build/app/outputs/flutter-apk/app-profile.apk"
        ;;
    3)
        echo -e "${BLUE}Building release version...${NC}"
        flutter build apk --release
        build_file="build/app/outputs/flutter-apk/app-release.apk"
        ;;
    *)
        echo -e "${RED}Invalid choice. Defaulting to debug build.${NC}"
        flutter build apk --debug
        build_file="build/app/outputs/flutter-apk/app-debug.apk"
        ;;
esac

echo ""
if [ -f "$build_file" ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo "APK location: $build_file"
    
    echo ""
    echo -e "${BLUE}Step 5: Installing to device...${NC}"
    
    # Extract Android devices for installation
    android_devices=$(echo "$devices_output" | grep "android" | awk '{print $2}')
    
    if [ ! -z "$android_devices" ]; then
        for device_id in $android_devices; do
            echo "Installing to device: $device_id"
            if command -v adb >/dev/null 2>&1; then
                adb -s "$device_id" install -r "$build_file"
            else
                echo -e "${YELLOW}⚠️  ADB not found. Install Android Studio for device installation${NC}"
            fi
        done
    else
        echo -e "${YELLOW}⚠️  No Android devices found for APK installation${NC}"
        echo "For iOS devices, use: ${GREEN}flutter install${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Installation complete!${NC}"
    echo "The Allma app should now be installed on your device."
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Check your device's app drawer for 'Allma'"
    echo "2. If testing, use: ${GREEN}flutter run${NC} for live development"
    echo "3. For debugging, use: ${GREEN}flutter logs${NC}"
    
else
    echo -e "${RED}❌ Build failed. Check the output above for errors.${NC}"
    exit 1
fi