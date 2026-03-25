# 🔑 iOS Code Signing Setup for Allma

Your iPhone 14 "Purple Brain" is detected and ready! You just need to configure code signing to deploy the app.

## ✅ Current Status
- ✅ iPhone 14 connected and detected
- ✅ Xcode properly configured  
- ✅ Flutter project ready
- 🔄 **Next: Code signing setup**

## 📋 Step-by-Step Code Signing Setup

### 1. In Xcode (already opened)
1. **Select "Runner" project** in left navigator
2. **Select "Runner" target** in main window  
3. **Click "Signing & Capabilities" tab**

### 2. Add Your Apple ID
1. **Xcode menu → Preferences → Accounts**
2. **Click "+" → Add Apple ID**
3. **Enter your Apple ID and password**
4. **Click "Manage Certificates"**
5. **Click "+" → iOS Development** (if not already present)

### 3. Configure Team in Project
1. **Back in Runner → Signing & Capabilities**
2. **Select your Apple ID team** from "Team" dropdown
3. **Xcode will automatically:**
   - Generate development certificate
   - Create provisioning profile
   - Register your device

### 4. Trust Certificate on iPhone
1. **iPhone Settings → General → VPN & Device Management**
2. **Find your Apple ID certificate**
3. **Tap → Trust → Trust**

## 🚀 After Setup Complete

Run this command to deploy to your iPhone:
```bash
flutter run -d 00008120-0016712A1160201E
```

## 🔧 Alternative: Free Apple Developer Account

If you don't have a paid Apple Developer account:
1. Use your personal Apple ID (free)
2. Apps expire after 7 days (need to reinstall)
3. Perfect for testing and development

## ⚡ Quick Test Commands

```bash
# Check if device is still detected
flutter devices

# Run on iPhone (after code signing setup)
flutter run -d 00008120-0016712A1160201E

# Run with verbose output for debugging
flutter run -v -d 00008120-0016712A1160201E

# Hot reload during development
# Press 'r' for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

## 🐛 Troubleshooting

### Certificate Issues
```bash
# Clean and rebuild if needed
flutter clean
flutter pub get
```

### Device Trust Issues
- Make sure "Trust This Computer" is accepted on iPhone
- Check Developer Mode is enabled: Settings → Privacy & Security → Developer Mode

### Bundle ID Conflicts
- Current Bundle ID: `com.exxede.allma`
- Change in Xcode if needed: Runner → General → Bundle Identifier

## ✨ What Happens Next

Once code signing is configured:
1. ✅ App will build for iOS
2. ✅ Deploy directly to your iPhone 14
3. ✅ Hot reload/restart will work
4. ✅ You can test all Allma features natively

The Allma AI Companion app will then run as a native iOS application on your iPhone 14, giving you the full mobile experience instead of just the web browser version!