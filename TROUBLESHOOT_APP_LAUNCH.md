# 🔧 Allma App Launch Troubleshooting

The app installed but won't open - this is a common iOS security issue. Here's how to fix it:

## 📱 iPhone Settings Fix (Most Common)

### Step 1: Trust Developer Certificate
1. **iPhone Settings → General → VPN & Device Management**
2. **Look for**: "Developer App" section
3. **Find**: "armandodiazsilverio@gmail.com" or "626WU844CN"
4. **Tap it** → **Trust** → **Trust** (confirm)

### Step 2: Enable Developer Mode (if prompted)
1. **Settings → Privacy & Security → Developer Mode**
2. **Turn ON** Developer Mode
3. **Restart iPhone** when prompted
4. **Enter passcode** to confirm

## 🛠️ Alternative Solutions

### If Certificate Not Showing:
1. **Try opening app first** - tap Allma icon
2. **Error message will appear** with certificate info
3. **Then go to Settings** to trust it

### Force Refresh Certificate:
Run this to reinstall with fresh certificate:
```bash
flutter clean
flutter run -d 00008120-0016712A1160201E
```

## 🔍 Check App Installation

### Verify App is Installed:
- **Swipe down** on home screen
- **Search "Allma"** 
- Should show the app icon

### Check Developer Certificate:
- **Settings → General → VPN & Device Management**
- **Device Management** section
- Should show: **Apple Development: armandodiazsilverio@gmail.com**

## 🚀 Once Fixed:

After trusting the certificate:
1. **Tap Allma app** - should open normally
2. **Full native iOS experience**
3. **Hot reload available** for development

## ⚡ Quick Commands

```bash
# Check device connection
flutter devices

# Reinstall if needed
flutter run -d 00008120-0016712A1160201E

# View logs if app crashes
flutter logs
```

The app is properly installed - just needs iOS security trust setup!