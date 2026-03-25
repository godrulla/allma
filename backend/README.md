# Allma Backend API

Backend API server for the Allma AI Companion mobile application, built with Node.js, Express, TypeScript, Firebase, and Google Gemini AI.

## Features

- **Authentication**: Firebase Auth integration with JWT tokens
- **Real-time Messaging**: Socket.io for live chat functionality
- **AI Integration**: Google Gemini API for character responses
- **Character Management**: Create, customize, and manage AI companions
- **Conversation History**: Persistent chat storage with Firebase Firestore
- **File Uploads**: Image and media handling
- **Rate Limiting**: API protection and abuse prevention
- **Comprehensive Logging**: Winston-based logging system

## Getting Started

### Prerequisites

- Node.js 18+
- Firebase project with Firestore and Auth enabled
- Google Gemini API key

### Installation

1. Clone the repository and navigate to backend:
```bash
cd backend
npm install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Configure Firebase:
   - Download your service account key from Firebase Console
   - Update Firebase configuration in `.env`

4. Start development server:
```bash
npm run dev
```

## Environment Variables

Create a `.env` file with the following variables:

```env
# Server
PORT=3000
NODE_ENV=development

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-Key\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=service-account@project.iam.gserviceaccount.com
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com
FIREBASE_STORAGE_BUCKET=your-project.appspot.com

# Google AI
GEMINI_API_KEY=your-gemini-api-key

# Authentication
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRY=7d

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Create new user account
- `POST /api/auth/signin` - Sign in with email/password
- `POST /api/auth/firebase-auth` - Sign in with Firebase token
- `POST /api/auth/reset-password` - Send password reset email

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `PUT /api/users/preferences` - Update user preferences
- `GET /api/users/stats` - Get user statistics
- `DELETE /api/users/account` - Delete user account

### Characters
- `POST /api/characters/create` - Create new character
- `GET /api/characters/my-characters` - Get user's characters
- `GET /api/characters/public` - Get public characters
- `GET /api/characters/:id` - Get character by ID
- `PUT /api/characters/:id` - Update character
- `DELETE /api/characters/:id` - Delete character
- `POST /api/characters/:id/clone` - Clone public character

### Chat
- `POST /api/chat/send` - Send message to character
- `GET /api/chat/conversations` - Get user's conversations
- `GET /api/chat/conversation/:id/messages` - Get conversation messages
- `DELETE /api/chat/conversation/:id` - Delete conversation

## WebSocket Events

### Client to Server
- `authenticate` - Authenticate socket connection
- `join_conversation` - Join conversation room
- `leave_conversation` - Leave conversation room
- `typing_start` - Notify typing started
- `typing_stop` - Notify typing stopped
- `message_reaction` - Add/remove message reaction

### Server to Client
- `authenticated` - Authentication successful
- `new_message` - New message in conversation
- `user_typing` - User typing status
- `message_reaction_updated` - Message reactions updated
- `notification` - System notifications

## Database Schema

### Users Collection
```typescript
{
  id: string;
  email: string;
  displayName: string;
  photoURL: string | null;
  preferences: UserPreferences;
  subscription: Subscription;
  createdAt: Date;
  updatedAt: Date;
}
```

### Characters Collection
```typescript
{
  id: string;
  userId: string;
  name: string;
  avatar: string;
  personality: Personality;
  currentMood: string;
  relationshipLevel: number;
  memories: Memory[];
  isPublic: boolean;
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}
```

### Conversations Collection
```typescript
{
  id: string;
  userId: string;
  characterId: string;
  startedAt: Date;
  lastMessageAt: Date;
  summary?: string;
  topics?: string[];
  mood?: string;
  isActive: boolean;
}
```

## Development

### Scripts
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm start           # Start production server
npm run test        # Run tests
npm run lint        # Run ESLint
npm run typecheck   # Run TypeScript check
```

### Testing
```bash
npm run test                    # Run all tests
npm run test:watch             # Run tests in watch mode
npm run test:coverage          # Run tests with coverage
```

## Deployment

1. Build the application:
```bash
npm run build
```

2. Set production environment variables

3. Deploy to your hosting platform (Railway, Heroku, GCP, etc.)

## Security Features

- JWT token authentication
- Firebase security rules
- Rate limiting on all endpoints
- Input validation with Joi
- Helmet.js security headers
- CORS protection
- Password hashing with bcrypt
- Content moderation via Gemini AI

## Monitoring and Logging

- Winston logger with multiple transports
- Request/response logging
- Error tracking
- Performance monitoring
- Health check endpoint: `GET /health`

## License

MIT License - see LICENSE file for details