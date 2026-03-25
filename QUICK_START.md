# 🚀 Allma Quick Start Guide

Your Allma AI companion app is almost ready! Follow these final steps to get started.

## ✅ What's Already Configured

- ✅ **Voice Recording & Playback**: Full waveform visualization
- ✅ **Speech Recognition**: Real-time voice-to-text
- ✅ **Text-to-Speech**: AI companion can speak responses
- ✅ **AI Image Generation**: 5 artistic styles available
- ✅ **Multimedia Chat**: Voice, text, and image messages
- ✅ **Platform Permissions**: Android & iOS permissions configured
- ✅ **Dependencies**: All required packages installed

## 🔑 Only API Key Needed

### **Get Your Gemini API Key** (2 minutes):

1. **Visit**: https://makersuite.google.com/app/apikey
2. **Sign in** with Google account
3. **Click "Create API Key"**
4. **Copy the key** (starts with `AIza...`)

### **Add to Your App**:

1. **Open**: `.env` in the project root
2. **Replace**: 
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   ```
   **With your actual key**:
   ```env
   GEMINI_API_KEY=AIza_your_actual_key_here
   ```
3. **Save the file**

## 🧪 Test Your Setup

Run the verification script:
```bash
dart scripts/verify_api_setup.dart
```

If everything shows ✅, you're ready!

## 🚀 Launch Your App

```bash
flutter run
```

## 🎯 Features to Test

### 1. **AI Chat**
- Send a text message to your companion
- Ask questions, have conversations

### 2. **Voice Messages**
- **Hold** the microphone button
- **Speak** your message
- **Release** to send
- **Tap** voice messages to play with waveform

### 3. **AI Image Generation**
- **Tap** attachment button (📎)
- **Select** "Generate Image"
- **Describe** what you want to create
- **Choose** an art style
- **Generate** and send!

### 4. **Camera & Gallery**
- **Tap** attachment button (📎)
- **Select** "Camera" or "Gallery"
- **Pick/Take** a photo
- **Send** to your companion

## 🔧 Troubleshooting

### **"API Key Invalid"**
- Verify the key starts with `AIza`
- No extra spaces in the `.env` file
- Enable APIs at: https://console.cloud.google.com/apis/library

### **"Permission Denied"**
- Grant microphone/camera permissions in device settings
- Restart the app after granting permissions

### **Voice Features Not Working**
- Test device's built-in voice recorder first
- Check internet connection
- Ensure microphone isn't blocked by other apps

## 💰 Cost Monitoring

Your usage will be tracked at:
https://console.cloud.google.com/apis/dashboard

**Typical costs**:
- Text messages: ~$0.002 per 1K tokens
- Image generation: ~$0.04 per image
- Voice features: **Free** (uses device capabilities)

## 🎉 You're Ready!

Your Allma AI companion now has:
- 🗣️ **Voice conversations** with real-time transcription
- 🎨 **AI image generation** with multiple artistic styles
- 📱 **Multimedia messaging** with smooth animations
- 🤖 **Intelligent responses** powered by Gemini AI

Enjoy building relationships with your AI companion! ✨

---

**Need help?** Check the full `API_SETUP_GUIDE.md` for detailed troubleshooting.