#!/bin/bash

# Deploy to iPhone without Xcode GUI
echo "🚀 Deploying Allma to iPhone 14 without Xcode GUI"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Device ID
DEVICE_ID="00008120-0016712A1160201E"

echo -e "${BLUE}Step 1: Setting up automatic provisioning...${NC}"

# Create a minimal entitlements file
cat > ios/Runner/Runner.entitlements <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.team-identifier</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
EOF

echo -e "${BLUE}Step 2: Creating development build...${NC}"

# Build without code signing
flutter build ios --debug --no-codesign

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    echo ""
    echo -e "${BLUE}Step 3: Installing to device...${NC}"
    
    # Try to install using ios-deploy
    ios-deploy --bundle build/ios/iphoneos/Runner.app --device $DEVICE_ID --no-wifi
    
    if [ $? -ne 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Direct install failed. Trying alternative...${NC}"
        
        # Alternative: Use Flutter install
        flutter install -d $DEVICE_ID
    fi
else
    echo -e "${RED}❌ Build failed${NC}"
    echo ""
    echo -e "${YELLOW}Alternative: Web Testing${NC}"
    echo "Run: flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080"
    echo "Then visit on iPhone: http://$(ipconfig getifaddr en0):8080"
fi

echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "1. If code signing fails, you need to set up Apple ID in Xcode"
echo "2. For web testing as alternative: flutter run -d chrome --web-hostname 0.0.0.0"
echo "3. To open Xcode manually: open ios/Runner.xcworkspace"