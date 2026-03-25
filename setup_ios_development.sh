#!/bin/bash

# iOS Development Setup for Allma
echo "📱 Setting up iOS Development Environment"
echo "========================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Checking Xcode installation...${NC}"

if xcode-select -p >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Xcode command line tools found${NC}"
    echo "Location: $(xcode-select -p)"
else
    echo -e "${YELLOW}⚠️  Xcode command line tools not found${NC}"
    echo "Installing Xcode command line tools..."
    xcode-select --install
    echo "Please wait for installation to complete, then run this script again."
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Checking full Xcode installation...${NC}"

if [ -d "/Applications/Xcode.app" ]; then
    echo -e "${GREEN}✅ Xcode.app found${NC}"
    
    echo ""
    echo -e "${BLUE}Step 3: Setting up Xcode developer tools...${NC}"
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    
    echo ""
    echo -e "${BLUE}Step 4: Running Xcode first launch setup...${NC}"
    sudo xcodebuild -runFirstLaunch
    
else
    echo -e "${RED}❌ Xcode.app not found${NC}"
    echo ""
    echo "Please install Xcode from one of these methods:"
    echo "1. App Store: Search for 'Xcode' and install"
    echo "2. Developer Portal: https://developer.apple.com/xcode/"
    echo ""
    echo "After installing Xcode, run this script again."
    exit 1
fi

echo ""
echo -e "${BLUE}Step 5: Installing CocoaPods...${NC}"

if command -v pod >/dev/null 2>&1; then
    echo -e "${GREEN}✅ CocoaPods already installed${NC}"
    pod --version
else
    echo "Installing CocoaPods..."
    
    # Check if Ruby is available and install via gem
    if command -v gem >/dev/null 2>&1; then
        sudo gem install cocoapods
        pod setup
    else
        echo -e "${YELLOW}⚠️  Ruby not found. Installing via Homebrew...${NC}"
        
        # Install Homebrew if not present
        if ! command -v brew >/dev/null 2>&1; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        brew install cocoapods
    fi
fi

echo ""
echo -e "${BLUE}Step 6: Accepting Xcode license...${NC}"
sudo xcodebuild -license accept

echo ""
echo -e "${BLUE}Step 7: Installing iOS Simulator (if needed)...${NC}"
xcodebuild -downloadPlatform iOS

echo ""
echo -e "${BLUE}Step 8: Checking Flutter iOS setup...${NC}"
flutter doctor

echo ""
echo -e "${GREEN}🎉 iOS Development Setup Complete!${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Make sure your iPhone is connected via USB"
echo "2. On your iPhone: Settings → General → Device Management"
echo "3. Trust your Apple ID/Developer account"
echo "4. Enable Developer Mode: Settings → Privacy & Security → Developer Mode"
echo "5. Run: ${GREEN}flutter devices${NC} to verify iPhone detection"
echo "6. Run: ${GREEN}./test_on_device.sh${NC} to start testing"

echo ""
echo -e "${YELLOW}📱 iPhone Setup Checklist:${NC}"
echo "□ iPhone connected via USB"
echo "□ 'Trust This Computer' accepted on iPhone"
echo "□ Developer Mode enabled on iPhone"
echo "□ Device shows up in 'flutter devices'"