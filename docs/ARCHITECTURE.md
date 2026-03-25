# Allma AI Companion App - Architecture Guide

## System Overview

Allma is designed as a modular, privacy-first AI companion application with a clear separation of concerns between UI, business logic, and data layers. The architecture prioritizes user privacy, scalability, and maintainability.

## High-Level Architecture

```
┌─────────────────────────────────────────┐
│              Mobile App (Flutter)       │
├─────────────────────────────────────────┤
│ Presentation Layer                      │
│ • Chat Interface                        │
│ • Companion Builder                     │
│ • Settings & Preferences                │
└─────────────────────────────────────────┘
                    │
┌─────────────────────────────────────────┐
│            Business Logic               │
├─────────────────────────────────────────┤
│ • Companion Management                  │
│ • Conversation Engine                   │
│ • Memory System                         │
│ • Safety & Moderation                   │
└─────────────────────────────────────────┘
                    │
┌─────────────────────────────────────────┐
│              Data Layer                 │
├─────────────────────────────────────────┤
│ • Local SQLite Database                 │
│ • Encrypted Storage                     │
│ • Vector Database (Memory)              │
│ • File System (Assets)                  │
└─────────────────────────────────────────┘
                    │
┌─────────────────────────────────────────┐
│            External Services            │
├─────────────────────────────────────────┤
│ • Google Gemini API                     │
│ • Imagen 4 Fast                         │
│ • Text-to-Speech                        │
│ • Firebase Auth (Optional)              │
└─────────────────────────────────────────┘
```

## Core Components

### 1. Companion System

The companion system is the heart of Allma, managing AI entities that users interact with.

#### Companion Model
```dart
class Companion {
  final String id;
  final String name;
  final CompanionAppearance appearance;
  final CompanionPersonality personality;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;
}
```

#### Personality Engine
```dart
class CompanionPersonality {
  final Map<String, double> traits; // Big Five personality traits
  final String background;
  final String speakingStyle;
  final List<String> interests;
  final double creativity; // 0.0 - 1.0
  final double formality; // 0.0 - 1.0
}
```

### 2. Conversation Engine

Manages the flow of conversations between users and companions.

#### Message Flow
```
User Input → Safety Filter → Context Builder → Gemini API → Response Formatter → UI
```

#### Key Classes
- `ConversationManager`: Orchestrates chat sessions
- `MessageProcessor`: Handles message validation and formatting
- `ResponseGenerator`: Interfaces with Gemini API
- `ContextBuilder`: Manages conversation context and memory

### 3. Memory System

Implements a hierarchical memory structure for maintaining conversation context.

#### Memory Hierarchy
1. **Sensory Buffer**: Last 10 messages (immediate context)
2. **Short-term Memory**: Last 50 exchanges (session context)
3. **Long-term Memory**: Vector database (semantic memory)
4. **Working Memory**: Active context for current conversation

#### Implementation
```dart
class MemoryManager {
  final LocalMemoryStore localStore;
  final VectorMemoryStore vectorStore;
  
  Future<List<MemoryItem>> retrieveRelevant(String query) async {
    // Hybrid search: semantic + keyword + recency
  }
}
```

### 4. Safety & Moderation

Multi-layered safety system ensuring user protection and appropriate content.

#### Safety Layers
1. **Input Filtering**: User message content analysis
2. **Response Filtering**: AI response validation
3. **Crisis Detection**: Mental health and emergency intervention
4. **Content Moderation**: Inappropriate content blocking

#### Crisis Intervention
```dart
class CrisisInterventionSystem {
  final List<CrisisDetector> detectors;
  final EmergencyResourceProvider resources;
  
  Future<InterventionResponse> analyzeForCrisis(String message) async {
    // Multi-model crisis detection
  }
}
```

## Data Architecture

### Local Database Schema

```sql
-- Companions table
CREATE TABLE companions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    appearance_data TEXT, -- JSON
    personality_data TEXT, -- JSON
    created_at INTEGER,
    updated_at INTEGER
);

-- Conversations table
CREATE TABLE conversations (
    id TEXT PRIMARY KEY,
    companion_id TEXT,
    user_message TEXT,
    companion_response TEXT,
    timestamp INTEGER,
    metadata TEXT, -- JSON
    FOREIGN KEY (companion_id) REFERENCES companions(id)
);

-- Memory items table
CREATE TABLE memory_items (
    id TEXT PRIMARY KEY,
    companion_id TEXT,
    content TEXT,
    embedding BLOB, -- Vector embedding
    importance_score REAL,
    created_at INTEGER,
    FOREIGN KEY (companion_id) REFERENCES companions(id)
);

-- User preferences table
CREATE TABLE user_preferences (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at INTEGER
);
```

### Encryption Strategy

All sensitive data is encrypted before storage:

```dart
class EncryptionService {
  static const String keyAlias = 'allma_master_key';
  
  Future<String> encrypt(String plaintext) async {
    // AES-256-GCM encryption
  }
  
  Future<String> decrypt(String ciphertext) async {
    // AES-256-GCM decryption
  }
}
```

## State Management

### Riverpod Architecture

```dart
// Companion state
final companionProvider = StateNotifierProvider<CompanionNotifier, List<Companion>>(
  (ref) => CompanionNotifier(ref.read(companionRepositoryProvider)),
);

// Conversation state
final conversationProvider = StateNotifierProvider.family<ConversationNotifier, ConversationState, String>(
  (ref, companionId) => ConversationNotifier(companionId, ref.read(conversationServiceProvider)),
);

// Settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>(
  (ref) => SettingsNotifier(ref.read(settingsRepositoryProvider)),
);
```

## AI Integration

### Gemini API Integration

```dart
class GeminiService {
  final Dio _dio;
  final String _apiKey;
  
  Future<String> generateResponse({
    required List<Message> conversationHistory,
    required CompanionPersonality personality,
    required List<MemoryItem> relevantMemories,
  }) async {
    final prompt = _buildPrompt(personality, relevantMemories);
    final messages = _formatMessages(conversationHistory);
    
    final response = await _dio.post(
      '/v1/models/gemini-2.5-flash:generateContent',
      data: {
        'contents': messages,
        'systemInstruction': prompt,
        'generationConfig': {
          'temperature': personality.creativity,
          'maxOutputTokens': 1024,
          'topP': 0.95,
          'topK': 40,
        },
      },
    );
    
    return _extractResponse(response.data);
  }
}
```

### Context Optimization

```dart
class ContextOptimizer {
  static const int maxTokens = 8000; // Leave room for response
  
  String optimizeContext({
    required String systemPrompt,
    required List<Message> messages,
    required List<MemoryItem> memories,
  }) {
    // Token counting and intelligent truncation
    // Preserve recent messages and high-importance memories
  }
}
```

## Security Architecture

### Authentication (Optional)

```dart
class AuthService {
  Future<User?> signInAnonymously() async {
    // Anonymous authentication for privacy
  }
  
  Future<User?> signInWithGoogle() async {
    // Optional Google sign-in
  }
}
```

### Data Protection

1. **Encryption at Rest**: All local data encrypted with device keystore
2. **Encryption in Transit**: HTTPS/WSS for all network communication
3. **API Key Security**: Secure storage of Gemini API keys
4. **Biometric Authentication**: Optional app lock with biometrics

## Performance Optimization

### Caching Strategy

```dart
class CacheManager {
  final LRUCache<String, String> responseCache;
  final LRUCache<String, List<MemoryItem>> memoryCache;
  
  // Context caching for Gemini API cost optimization
  Future<String> getCachedContext(String contextHash) async {
    // 75% cost reduction through context caching
  }
}
```

### Image Optimization

```dart
class ImageCacheManager extends CacheManager {
  String buildOptimizedUrl(String baseUrl, {int? width, int? height}) {
    // WebP format, quality optimization, CDN integration
  }
}
```

## Scalability Considerations

### Horizontal Scaling

- **Stateless Architecture**: All user state stored locally
- **API Gateway**: Rate limiting and request distribution
- **CDN Integration**: Static asset delivery optimization
- **Database Sharding**: User data partitioning for growth

### Performance Targets

- **Response Time**: < 2 seconds for AI responses
- **App Launch**: < 3 seconds cold start
- **Memory Usage**: < 150MB on device
- **Battery Impact**: < 5% per hour of active use
- **Offline Support**: Queue messages for later sync

## Monitoring & Analytics

### Performance Monitoring

```dart
class PerformanceMonitor {
  void trackAPILatency(String endpoint, Duration latency) {
    // Track Gemini API response times
  }
  
  void trackMemoryUsage(int memoryBytes) {
    // Monitor app memory consumption
  }
  
  void trackUserEngagement(String event, Map<String, dynamic> properties) {
    // Privacy-preserving analytics
  }
}
```

### Error Handling

```dart
class ErrorHandler {
  void handleAPIError(ApiException error) {
    // Graceful degradation for API failures
  }
  
  void handleLocalStorageError(StorageException error) {
    // Data recovery and backup strategies
  }
}
```

## Testing Strategy

### Test Pyramid

1. **Unit Tests**: Core business logic (80%)
2. **Widget Tests**: UI components (15%)
3. **Integration Tests**: End-to-end flows (5%)

### Test Categories

- **Companion Logic Tests**: Personality engine, memory system
- **AI Integration Tests**: Mocked Gemini API responses
- **Security Tests**: Encryption, data protection
- **Performance Tests**: Memory usage, response times
- **Accessibility Tests**: Screen reader, navigation

## Deployment Architecture

### Mobile App Distribution

- **iOS**: App Store deployment with TestFlight beta
- **Android**: Google Play Store with staged rollout
- **Web**: Progressive Web App for browser access

### CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter analyze
  build:
    runs-on: ubuntu-latest
    steps:
      - run: flutter build apk --release
      - run: flutter build ios --release
```

This architecture ensures scalability, maintainability, and user privacy while providing a robust foundation for the Allma AI companion experience.