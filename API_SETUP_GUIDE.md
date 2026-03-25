# 🔑 API Keys Setup Guide for Allma

This guide will walk you through setting up all necessary API keys for your Allma AI companion app.

## 📋 Required Services & API Keys

### ✅ **Google Gemini API** (Required)
- **Purpose**: AI text generation and image generation
- **Cost**: Free tier: 15 requests/minute, then $0.002-0.008 per 1K tokens
- **Setup Time**: 5 minutes

### ✅ **Built-in Device Services** (No API keys needed)
- **Speech Recognition**: Uses device's native speech-to-text
- **Text-to-Speech**: Uses device's native TTS engine
- **Voice Recording**: Uses device microphone with permissions

---

## 🚀 Step-by-Step Setup

### Step 1: Google Gemini API Key

1. **Go to Google AI Studio**:
   ```
   https://makersuite.google.com/app/apikey
   ```

2. **Sign in** with your Google account

3. **Create a new API key**:
   - Click "Create API Key"
   - Choose "Create API key in new project" or select existing project
   - Copy the generated API key (starts with `AIza...`)

4. **Enable required APIs** in Google Cloud Console:
   ```
   https://console.cloud.google.com/apis/library
   ```
   - Search for "Generative Language API" → Enable
   - Search for "Vertex AI API" → Enable (for image generation)

### Step 2: Configure Your App

1. **Open your `.env` file** in the project root

2. **Replace the placeholder** with your actual API key:
   ```env
   GEMINI_API_KEY=AIza_your_actual_api_key_here
   ```

3. **Verify other settings** (optional to modify):
   ```env
   # AI Model Configuration
   GEMINI_MODEL=gemini-2.5-flash
   IMAGE_MODEL=imagen-3.0-generate-001
   
   # Development Settings
   DEBUG_MODE=true
   LOG_LEVEL=verbose
   ```

### Step 3: Test Your Setup

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Test features**:
   - ✅ **Text Chat**: Send a message to your companion
   - ✅ **Voice Recording**: Hold voice button and speak
   - ✅ **Image Generation**: Tap attachment → "Generate Image"

---

## 🔒 Security Best Practices

### ✅ **Protect Your API Keys**
- Never commit API keys to version control
- The `.env` file is already in `.gitignore`
- Use different keys for development/production

### ✅ **Set Usage Limits**
1. **In Google Cloud Console**:
   ```
   https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas
   ```
2. **Set daily/monthly limits** to prevent unexpected charges

### ✅ **Monitor Usage**
- Check usage at: https://console.cloud.google.com/apis/dashboard
- Set up billing alerts in Google Cloud

---

## 💰 Cost Estimation

### **Google Gemini API Pricing** (as of 2024):

| Feature | Model | Free Tier | Paid Pricing |
|---------|-------|-----------|--------------|
| Text Chat | Gemini 2.5 Flash | 15 RPM | $0.002/1K tokens |
| Image Generation | Imagen 3.0 | Limited | $0.04/image |

### **Estimated Monthly Costs**:
- **Light usage** (100 messages, 20 images): ~$2-5
- **Moderate usage** (500 messages, 50 images): ~$10-15
- **Heavy usage** (2000 messages, 200 images): ~$30-50

---

## 🛠️ Troubleshooting

### **API Key Issues**

❌ **"Bad Request" or "Unauthorized" errors**:
- Verify API key is correct (no extra spaces)
- Ensure APIs are enabled in Google Cloud Console
- Check API key has necessary permissions

❌ **"Quota exceeded" errors**:
- Check your usage limits in Google Cloud Console
- Upgrade to paid tier if needed
- Wait for quota reset (usually daily)

### **Voice Features Not Working**

❌ **Speech recognition fails**:
- Grant microphone permissions in device settings
- Test with device's default voice recognition app
- Ensure device has internet connection

❌ **Voice recording issues**:
- Check microphone permissions
- Test with other recording apps
- Restart the app

### **Image Generation Issues**

❌ **Images not generating**:
- Verify Vertex AI API is enabled
- Check if Imagen is available in your region
- Try simpler prompts first

---

## 🎯 Quick Start Checklist

- [ ] 1. Get Gemini API key from Google AI Studio
- [ ] 2. Enable Generative Language API and Vertex AI API
- [ ] 3. Update `GEMINI_API_KEY` in `.env` file
- [ ] 4. Run `flutter run` to test
- [ ] 5. Test chat, voice, and image generation
- [ ] 6. Set usage limits in Google Cloud Console
- [ ] 7. Monitor usage and costs

---

## 📞 Support

If you encounter issues:

1. **Check the console logs** when running the app
2. **Verify API key permissions** in Google Cloud Console
3. **Test with simple prompts** first
4. **Check device permissions** for microphone/camera

**Common error codes**:
- `400`: Bad request (check API key format)
- `401`: Unauthorized (check API key permissions)
- `429`: Quota exceeded (upgrade or wait)
- `403`: API not enabled (enable in Cloud Console)

---

## 🚀 You're Ready!

Once you've completed this setup, your Allma app will have:
- ✅ AI-powered chat conversations
- ✅ Voice message recording and playback
- ✅ Speech-to-text transcription
- ✅ AI image generation with multiple styles
- ✅ Text-to-speech for companion responses

Enjoy building with Allma! 🤖✨