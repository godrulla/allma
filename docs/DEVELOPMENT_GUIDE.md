# Allma Development Guide

## Getting Started

This guide will help you set up your development environment and understand the Allma codebase.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.16.0 or later)
   ```bash
   # Install Flutter using fvm for version management
   dart pub global activate fvm
   fvm install 3.16.0
   fvm use 3.16.0
   ```

2. **Dart SDK** (3.2.0 or later)
   - Comes with Flutter SDK

3. **IDE Setup**
   - **VS Code** with Flutter extension
   - **Android Studio** with Flutter and Dart plugins

4. **Mobile Development Tools**
   - **Android Studio** for Android development
   - **Xcode** (macOS only) for iOS development

### Google Cloud Setup

1. **Create Google Cloud Project**
   ```bash
   gcloud projects create allma-companion-dev
   gcloud config set project allma-companion-dev
   ```

2. **Enable APIs**
   ```bash
   gcloud services enable generativelanguage.googleapis.com
   gcloud services enable texttospeech.googleapis.com
   gcloud services enable translate.googleapis.com
   ```

3. **Create API Key**
   ```bash
   gcloud alpha services api-keys create --display-name="Allma Development Key"
   ```

## Project Setup

### Clone and Install

```bash
# Clone the repository
git clone https://github.com/exxede/allma-ai-companion.git
cd allma-ai-companion

# Install dependencies
flutter pub get

# Generate code (if needed)
flutter pub run build_runner build
```

### Environment Configuration

1. **Create environment file**
   ```bash
   cp .env.example .env
   ```

2. **Configure .env file**
   ```bash
   # Google AI API Configuration
   GEMINI_API_KEY=your_gemini_api_key_here
   
   # Optional: Firebase Configuration
   FIREBASE_PROJECT_ID=your_firebase_project_id
   
   # Development Settings
   DEBUG_MODE=true
   LOG_LEVEL=verbose
   
   # Feature Flags
   ENABLE_ANALYTICS=false
   ENABLE_CRASH_REPORTING=false
   ```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/                         # App-level configuration
│   ├── app.dart                 # Main app widget
│   ├── router.dart              # App routing
│   └── theme.dart               # App theming
├── core/                        # Core business logic
│   ├── companions/              # Companion system
│   │   ├── models/              # Companion data models
│   │   ├── repositories/        # Data access layer
│   │   ├── services/            # Business logic
│   │   └── providers/           # State management
│   ├── ai/                      # AI integration
│   │   ├── gemini_service.dart  # Gemini API client
│   │   ├── context_manager.dart # Context handling
│   │   └── response_formatter.dart # Response processing
│   ├── memory/                  # Memory management
│   │   ├── memory_store.dart    # Memory storage
│   │   ├── vector_search.dart   # Semantic search
│   │   └── memory_manager.dart  # Memory orchestration
│   └── safety/                  # Safety systems
│       ├── content_filter.dart  # Content moderation
│       ├── crisis_detector.dart # Crisis intervention
│       └── safety_service.dart  # Safety orchestration
├── features/                    # Feature modules
│   ├── chat/                    # Chat interface
│   │   ├── models/              # Chat-specific models
│   │   ├── widgets/             # Chat UI components
│   │   ├── providers/           # Chat state management
│   │   └── pages/               # Chat screens
│   ├── companion_creation/      # Companion builder
│   │   ├── models/              # Creation models
│   │   ├── widgets/             # Creation UI components
│   │   ├── providers/           # Creation state
│   │   └── pages/               # Creation screens
│   └── settings/                # User preferences
│       ├── models/              # Settings models
│       ├── widgets/             # Settings UI
│       ├── providers/           # Settings state
│       └── pages/               # Settings screens
├── shared/                      # Shared components
│   ├── widgets/                 # Reusable UI components
│   │   ├── buttons/             # Custom buttons
│   │   ├── inputs/              # Input components
│   │   ├── cards/               # Card components
│   │   └── animations/          # Animation widgets
│   ├── utils/                   # Helper functions
│   │   ├── constants.dart       # App constants
│   │   ├── extensions.dart      # Dart extensions
│   │   ├── validators.dart      # Input validation
│   │   └── helpers.dart         # Utility functions
│   ├── services/                # Shared services
│   │   ├── storage_service.dart # Local storage
│   │   ├── encryption_service.dart # Data encryption
│   │   └── network_service.dart # Network utilities
│   └── models/                  # Shared data models
│       ├── message.dart         # Message model
│       ├── user.dart            # User model
│       └── api_response.dart    # API response wrapper
└── gen/                         # Generated code
    ├── assets.gen.dart          # Asset references
    └── colors.gen.dart          # Color constants
```

## Development Workflow

### State Management with Riverpod

```dart
// Provider definition
final companionProvider = StateNotifierProvider<CompanionNotifier, AsyncValue<List<Companion>>>(
  (ref) => CompanionNotifier(ref.read(companionRepositoryProvider)),
);

// Usage in widgets
class CompanionListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(companionProvider);
    
    return companionsAsync.when(
      data: (companions) => ListView.builder(
        itemCount: companions.length,
        itemBuilder: (context, index) => CompanionCard(companions[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### Database Operations

```dart
// Repository pattern example
abstract class CompanionRepository {
  Future<List<Companion>> getAllCompanions();
  Future<Companion?> getCompanion(String id);
  Future<void> saveCompanion(Companion companion);
  Future<void> deleteCompanion(String id);
}

class LocalCompanionRepository implements CompanionRepository {
  final Database _database;
  final EncryptionService _encryption;
  
  @override
  Future<void> saveCompanion(Companion companion) async {
    final encryptedData = await _encryption.encrypt(
      json.encode(companion.toJson()),
    );
    
    await _database.insert('companions', {
      'id': companion.id,
      'encrypted_data': encryptedData,
      'created_at': companion.createdAt.millisecondsSinceEpoch,
    });
  }
}
```

### AI Service Integration

```dart
// Service implementation
class GeminiConversationService {
  final GeminiService _geminiService;
  final MemoryManager _memoryManager;
  
  Future<String> generateResponse({
    required Companion companion,
    required String userMessage,
    required List<Message> history,
  }) async {
    // Retrieve relevant memories
    final memories = await _memoryManager.retrieveRelevantMemories(
      userMessage,
      companionId: companion.id,
    );
    
    // Build context
    final context = _buildContext(companion, userMessage, history, memories);
    
    // Generate response
    final response = await _geminiService.generateResponse(
      systemPrompt: companion.personality.generateSystemPrompt(),
      messages: context,
    );
    
    // Store new memories
    await _memoryManager.storeConversation(
      companionId: companion.id,
      userMessage: userMessage,
      companionResponse: response,
    );
    
    return response;
  }
}
```

## Testing

### Unit Testing

```dart
// Test example
void main() {
  group('CompanionPersonality', () {
    test('should generate system prompt correctly', () {
      final personality = CompanionPersonality(
        openness: 0.8,
        conscientiousness: 0.6,
        extraversion: 0.9,
        agreeableness: 0.7,
        neuroticism: 0.3,
        background: 'A friendly companion',
        interests: ['music', 'movies'],
        speakingStyle: 'Casual and warm',
      );
      
      final prompt = personality.generateSystemPrompt();
      
      expect(prompt, contains('Openness: 80%'));
      expect(prompt, contains('friendly companion'));
      expect(prompt, contains('music, movies'));
    });
  });
}
```

### Widget Testing

```dart
void main() {
  group('CompanionCard Widget', () {
    testWidgets('should display companion information', (tester) async {
      final companion = Companion(
        id: '1',
        name: 'Test Companion',
        appearance: CompanionAppearance.defaults(),
        personality: CompanionPersonality.friendly(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: CompanionCard(companion),
        ),
      );
      
      expect(find.text('Test Companion'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
```

### Integration Testing

```dart
void main() {
  group('Chat Flow Integration', () {
    testWidgets('should send message and receive response', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to chat
      await tester.tap(find.byKey(Key('companion_1')));
      await tester.pumpAndSettle();
      
      // Type message
      await tester.enterText(find.byKey(Key('message_input')), 'Hello');
      await tester.tap(find.byKey(Key('send_button')));
      await tester.pumpAndSettle();
      
      // Verify message appears
      expect(find.text('Hello'), findsOneWidget);
      
      // Wait for response (with timeout)
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Verify response appears
      expect(find.textContaining('Hello'), findsAtLeastNWidgets(2));
    });
  });
}
```

## Code Quality

### Linting Configuration

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - use_key_in_widget_constructors
```

### Code Formatting

```bash
# Format all Dart files
dart format lib/ test/

# Check formatting without applying
dart format --output=none --set-exit-if-changed lib/
```

### Static Analysis

```bash
# Run analyzer
flutter analyze

# Run with verbose output
flutter analyze --verbose
```

## Debugging

### Debug Configuration

```dart
// Debug utilities
class DebugConfig {
  static const bool isDebugMode = kDebugMode;
  static const LogLevel logLevel = LogLevel.verbose;
  
  static void log(String message, {LogLevel level = LogLevel.info}) {
    if (isDebugMode && level.index >= logLevel.index) {
      print('[${level.name.toUpperCase()}] $message');
    }
  }
}
```

### Performance Monitoring

```dart
class PerformanceMonitor {
  static void measureOperation(String name, Function operation) {
    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();
    
    DebugConfig.log(
      'Operation "$name" took ${stopwatch.elapsedMilliseconds}ms',
      level: LogLevel.debug,
    );
  }
}
```

## Build and Deployment

### Development Build

```bash
# Debug build for testing
flutter run --debug

# Profile build for performance testing
flutter run --profile

# Release build
flutter run --release
```

### Android Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

### iOS Build

```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Archive for App Store
flutter build ipa --release
```

### Environment-Specific Builds

```bash
# Development environment
flutter build apk --release --dart-define=ENVIRONMENT=development

# Production environment
flutter build apk --release --dart-define=ENVIRONMENT=production
```

## Common Issues and Solutions

### Flutter Doctor Issues

```bash
# Check Flutter installation
flutter doctor

# Fix Android license issues
flutter doctor --android-licenses

# Fix iOS issues (macOS only)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Build Issues

```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Reset iOS Pods (iOS only)
cd ios && rm -rf Pods Podfile.lock && pod install
```

### Performance Issues

1. **Use const constructors** where possible
2. **Implement proper list recycling** with ListView.builder
3. **Use RepaintBoundary** for expensive widgets
4. **Profile with Flutter Inspector** to identify performance bottlenecks

## Contributing Guidelines

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/companion-voice-chat

# Make changes and commit
git add .
git commit -m "feat: add voice chat capability to companions"

# Push and create PR
git push origin feature/companion-voice-chat
```

### Commit Message Format

```
type(scope): description

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes
- refactor: Code refactoring
- test: Adding tests
- chore: Maintenance tasks

Examples:
feat(chat): add voice message support
fix(memory): resolve memory leak in conversation storage
docs(api): update Gemini integration documentation
```

This development guide provides everything needed to start contributing to the Allma AI companion project.