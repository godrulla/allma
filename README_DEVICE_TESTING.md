# 📱 Allma Device Testing Guide

This guide provides comprehensive instructions for testing the Allma AI Companion app on physical iOS and Android devices.

## 🚀 Quick Start

1. **Run the main testing script:**
   ```bash
   ./test_on_device.sh
   ```

2. **For wireless setup:**
   ```bash
   ./setup_wireless_testing.sh
   ```

3. **To build and install APK:**
   ```bash
   ./build_and_install.sh
   ```

## 📱 iOS Device Setup

### Prerequisites
- Xcode installed on Mac
- iOS device with iOS 14.0 or later
- Apple Developer account (free tier is sufficient for testing)

### Setup Steps
1. **Enable Developer Mode:**
   - Settings → Privacy & Security → Developer Mode → Enable
   - Restart device when prompted

2. **Trust Computer:**
   - Connect iPhone via USB
   - When prompted, tap "Trust This Computer"
   - Enter device passcode

3. **Xcode Configuration:**
   - Open Xcode → Preferences → Accounts
   - Add your Apple ID
   - In project, set Team to your Apple ID

4. **Run on Device:**
   ```bash
   flutter run -d <ios-device-id>
   ```

### Wireless iOS Testing
1. Connect device via USB initially
2. Xcode → Window → Devices and Simulators
3. Select device → Check "Connect via network"
4. Once connected, unplug USB
5. Device appears with 🌐 icon in `flutter devices`

## 🤖 Android Device Setup

### Prerequisites
- Android device with Android 7.0 (API 24) or later
- USB cable
- Android Studio (optional, for ADB tools)

### Setup Steps
1. **Enable Developer Options:**
   - Settings → About Phone
   - Tap "Build Number" 7 times
   - "Developer options" now available in Settings

2. **Enable USB Debugging:**
   - Settings → Developer Options
   - Enable "USB Debugging"
   - Connect via USB and allow debugging when prompted

3. **Verify Connection:**
   ```bash
   flutter devices
   ```

4. **Run on Device:**
   ```bash
   flutter run -d <android-device-id>
   ```

### Wireless Android Testing
1. Connect device via USB initially
2. Enable USB Debugging
3. Run: `adb tcpip 5555`
4. Find device IP: Settings → About Phone → Status
5. Run: `adb connect <device-ip>:5555`
6. Unplug USB cable
7. Verify: `adb devices` should show `<ip>:5555 device`

## 🔧 Testing Scripts

### test_on_device.sh
Main testing script that:
- Checks Flutter installation
- Lists connected devices
- Provides setup instructions
- Allows device selection for testing
- Starts the app with hot reload

### setup_wireless_testing.sh  
Wireless debugging setup that:
- Configures iOS wireless debugging
- Sets up Android TCP debugging
- Provides IP connection commands
- Shows current device status

### build_and_install.sh
Build and deployment script that:
- Cleans previous builds
- Offers debug/profile/release builds
- Builds APK for Android
- Installs directly to connected devices
- Provides installation verification

## 🐛 Troubleshooting

### Device Not Detected
```bash
# Check USB connection
flutter devices

# For Android, check ADB
adb devices

# Reset ADB connection
adb kill-server && adb start-server

# For iOS, restart devices service
sudo pkill usbmuxd
```

### Build Failures
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Check for platform-specific issues
flutter doctor
```

### App Crashes on Device
```bash
# View real-time logs
flutter logs

# Debug with connected device
flutter run --debug -d <device-id>

# Profile performance issues  
flutter run --profile -d <device-id>
```

### Network/Wireless Issues
```bash
# Reset network debugging
adb disconnect
adb connect <device-ip>:5555

# Check firewall settings
# Ensure ports 5555 (Android) and dynamic iOS ports are open
```

## 📊 Performance Testing

### Memory Testing
```bash
# Run with memory profiling
flutter run --profile -d <device-id>

# Use Flutter Inspector in VS Code or Android Studio
# Monitor memory usage in real-time
```

### Battery Testing
- Run app for extended periods
- Monitor battery drain in device settings
- Test with different AI conversation loads
- Optimize based on power consumption data

### Network Testing
- Test on cellular vs WiFi
- Monitor API call frequency
- Test offline functionality
- Verify data usage optimization

## 🔒 Privacy Testing

### Encryption Verification
- Test local data encryption
- Verify secure storage functionality
- Check conversation data protection
- Validate key management

### Permissions Testing
- Test microphone permissions (if used)
- Verify storage permissions
- Check network access permissions
- Test graceful permission denial handling

## 📱 Platform-Specific Testing

### iOS Specific
- Test on different iOS versions (14.0+)
- Verify App Store guidelines compliance
- Test background app refresh
- Check iOS-specific UI elements

### Android Specific  
- Test on different Android versions (API 24+)
- Test on different screen sizes/densities
- Verify Android-specific permissions
- Test notification handling

## 🚀 Release Testing Checklist

- [ ] App builds successfully for both platforms
- [ ] All core features work on physical devices
- [ ] AI responses generate correctly
- [ ] Local storage and encryption work
- [ ] App performance meets targets (<150MB RAM)
- [ ] Battery usage is acceptable (<5%/hour)
- [ ] Network usage is optimized
- [ ] UI responds correctly to different screen sizes
- [ ] App handles network interruptions gracefully
- [ ] Privacy features work as expected
- [ ] Crash reporting and error handling work
- [ ] App store metadata and screenshots ready

## 📞 Support Commands

```bash
# Get comprehensive Flutter environment info
flutter doctor -v

# Check device details
flutter devices -v  

# Run with verbose logging
flutter run -v -d <device-id>

# Generate detailed crash reports
flutter symbolize --debug-info=<path-to-debug-info>
```

This testing framework ensures the Allma AI Companion app works reliably across all target devices and provides an excellent user experience.