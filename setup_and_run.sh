#!/bin/bash

# Allma Development Setup and Run Script
# This script will help you set up Flutter and run the Allma app

echo "================================================"
echo "     Allma AI Companion - Development Setup    "
echo "================================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check for Flutter installation
echo -e "${YELLOW}Step 1: Checking Flutter installation...${NC}"
if command_exists flutter; then
    echo -e "${GREEN}✓ Flutter is already installed${NC}"
    flutter --version
else
    echo -e "${RED}✗ Flutter is not installed${NC}"
    echo ""
    echo "Installing Flutter..."
    
    # Check OS type
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        echo "Detected macOS - Installing Flutter..."
        
        # Check for Homebrew
        if command_exists brew; then
            echo "Installing Flutter via Homebrew..."
            brew install --cask flutter
        else
            echo "Homebrew not found. Installing Flutter manually..."
            cd ~/
            git clone https://github.com/flutter/flutter.git -b stable
            export PATH="$PATH:`pwd`/flutter/bin"
            echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
            echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bash_profile
        fi
    else
        # Linux installation
        echo "Detected Linux - Installing Flutter..."
        cd ~/
        wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.5-stable.tar.xz
        tar xf flutter_linux_3.16.5-stable.tar.xz
        export PATH="$PATH:`pwd`/flutter/bin"
        echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    fi
    
    # Reload PATH
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || source ~/.bash_profile 2>/dev/null
fi

echo ""

# Step 2: Run Flutter doctor
echo -e "${YELLOW}Step 2: Running Flutter doctor...${NC}"
flutter doctor 2>/dev/null || echo "Please restart your terminal and run this script again if Flutter was just installed."

echo ""

# Step 3: Install dependencies
echo -e "${YELLOW}Step 3: Installing project dependencies...${NC}"
cd /Users/mando/Desktop/Allma

# Create a minimal pubspec.yaml if it doesn't have all required dependencies
if [ -f "pubspec.yaml" ]; then
    echo "Found pubspec.yaml, installing dependencies..."
    flutter pub get
else
    echo -e "${RED}pubspec.yaml not found or incomplete${NC}"
fi

echo ""

# Step 4: Set up environment variables
echo -e "${YELLOW}Step 4: Setting up environment variables...${NC}"
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Created .env file from .env.example${NC}"
        echo "Please edit .env file and add your Gemini API key"
    else
        # Create a basic .env file
        cat > .env << EOF
# Allma Environment Variables
GEMINI_API_KEY=your_gemini_api_key_here
API_BASE_URL=https://api.allma.app
ENVIRONMENT=development
ENABLE_LOGGING=true
EOF
        echo -e "${GREEN}✓ Created .env file${NC}"
        echo -e "${RED}IMPORTANT: Please edit .env file and add your Gemini API key${NC}"
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

echo ""

# Step 5: Check for device/emulator
echo -e "${YELLOW}Step 5: Checking for connected devices...${NC}"
flutter devices 2>/dev/null

echo ""
echo -e "${YELLOW}Available options to run Allma:${NC}"
echo ""
echo "1. Run on Chrome (Web)"
echo "2. Run on iOS Simulator (macOS only)"
echo "3. Run on Android Emulator"
echo "4. Run on connected physical device"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}Starting Allma on Chrome...${NC}"
        echo "================================================"
        echo ""
        flutter run -d chrome --web-port=8080
        ;;
    2)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo ""
            echo -e "${GREEN}Starting iOS Simulator...${NC}"
            open -a Simulator
            sleep 5
            echo -e "${GREEN}Starting Allma on iOS Simulator...${NC}"
            echo "================================================"
            echo ""
            flutter run -d iphone
        else
            echo -e "${RED}iOS Simulator is only available on macOS${NC}"
        fi
        ;;
    3)
        echo ""
        echo -e "${YELLOW}Make sure Android emulator is running${NC}"
        echo -e "${GREEN}Starting Allma on Android Emulator...${NC}"
        echo "================================================"
        echo ""
        flutter run -d emulator
        ;;
    4)
        echo ""
        echo -e "${YELLOW}Make sure your device is connected and debugging is enabled${NC}"
        echo -e "${GREEN}Starting Allma on connected device...${NC}"
        echo "================================================"
        echo ""
        flutter run
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "    Allma Development Server Instructions       "
echo "================================================"
echo ""
echo "If the app is running successfully:"
echo ""
echo "🔥 Hot Reload: Press 'r' in the terminal"
echo "🔄 Hot Restart: Press 'R' in the terminal"
echo "📱 Open DevTools: Press 'v' in the terminal"
echo "🛑 Quit: Press 'q' in the terminal"
echo ""
echo "Web URL (if running on Chrome): http://localhost:8080"
echo ""
echo "================================================"