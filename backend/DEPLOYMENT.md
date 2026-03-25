# Allma Backend Deployment Guide

## Quick Start

1. **Install dependencies**:
```bash
npm install
```

2. **Set up environment variables**:
```bash
cp .env.example .env
# Edit .env with your actual values
```

3. **Firebase Setup**:
   - Create a Firebase project at https://console.firebase.google.com
   - Enable Authentication and Firestore
   - Generate a service account key
   - Add the key details to your .env file

4. **Google AI Setup**:
   - Get a Gemini API key from https://aistudio.google.com/app/apikey
   - Add the key to your .env file

5. **Run the server**:
```bash
# Development
npm run dev

# Production
npm run build
npm start
```

## Environment Configuration

### Required Environment Variables

```env
# Server Configuration
PORT=3000
NODE_ENV=production

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-Private-Key-Here\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com
FIREBASE_STORAGE_BUCKET=your-project.appspot.com

# Google AI Configuration
GEMINI_API_KEY=your-gemini-api-key

# Authentication
JWT_SECRET=your-super-secure-jwt-secret-key
JWT_EXPIRY=7d

# CORS Origins (comma-separated)
ALLOWED_ORIGINS=https://your-app-domain.com,https://your-admin-domain.com
```

## Deployment Options

### 1. Railway

1. Connect your GitHub repository to Railway
2. Set environment variables in Railway dashboard
3. Deploy automatically on push

### 2. Google Cloud Platform

1. Build container:
```bash
gcloud builds submit --tag gcr.io/PROJECT-ID/allma-backend
```

2. Deploy to Cloud Run:
```bash
gcloud run deploy --image gcr.io/PROJECT-ID/allma-backend --platform managed
```

### 3. Heroku

1. Install Heroku CLI
2. Create app:
```bash
heroku create allma-backend
```

3. Set environment variables:
```bash
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=your-secret
# ... add all other variables
```

4. Deploy:
```bash
git push heroku main
```

### 4. Digital Ocean App Platform

1. Create new app from GitHub repository
2. Set environment variables in dashboard
3. Configure build settings:
   - Build command: `npm run build`
   - Run command: `npm start`

## Firebase Setup Details

### 1. Create Firebase Project
- Go to https://console.firebase.google.com
- Click "Create a project"
- Follow the setup wizard

### 2. Enable Services
- **Authentication**: Enable Email/Password and Google providers
- **Firestore**: Create database in production mode
- **Storage**: Set up for file uploads

### 3. Generate Service Account Key
- Go to Project Settings → Service Accounts
- Generate new private key
- Save the JSON file securely
- Extract the values for your .env file

### 4. Set Firestore Security Rules
Deploy the rules from `src/config/firestore.rules`:

```bash
firebase deploy --only firestore:rules
```

## Production Checklist

- [ ] Environment variables configured
- [ ] Firebase project set up with proper security rules
- [ ] Gemini API key obtained and configured
- [ ] JWT secret is cryptographically secure
- [ ] CORS origins configured for your domains
- [ ] Rate limiting configured appropriately
- [ ] Logging level set to 'info' or 'warn'
- [ ] Health check endpoint accessible
- [ ] SSL/TLS certificate configured
- [ ] Database backup strategy in place

## Monitoring & Logging

### Health Check
```bash
curl https://your-domain.com/health
```

### Logs
- Application logs are output to stdout/stderr
- Configure log aggregation (e.g., Papertrail, LogDNA)
- Set up error monitoring (e.g., Sentry)

### Analytics
- Monitor API response times
- Track user growth and engagement
- Monitor AI usage and costs

## Scaling Considerations

### Horizontal Scaling
- The app is stateless and can be scaled horizontally
- Use load balancer for multiple instances
- Socket.io requires sticky sessions or Redis adapter

### Database Scaling
- Firestore auto-scales but consider composite indexes
- Monitor read/write costs
- Implement caching for frequently accessed data

### AI API Limits
- Monitor Gemini API usage and costs
- Implement exponential backoff for rate limits
- Consider caching responses for common queries

## Security

### API Security
- All endpoints use rate limiting
- JWT tokens expire and must be refreshed
- Input validation on all endpoints
- CORS protection enabled

### Firebase Security
- Firestore rules prevent unauthorized access
- Service account key secured
- Authentication required for all operations

### Content Safety
- Gemini AI content filtering enabled
- Additional content moderation can be added
- User reporting system recommended