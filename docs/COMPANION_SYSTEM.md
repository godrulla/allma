# Allma Companion System Documentation

## Overview

The Companion System is the core of Allma, managing AI entities that users create and interact with. Each companion has a unique personality, appearance, memory, and conversation style that evolves through interactions.

## Companion Architecture

### Core Components

```dart
// Core companion model
class Companion {
  final String id;
  final String name;
  final CompanionAppearance appearance;
  final CompanionPersonality personality;
  final CompanionMemory memory;
  final CompanionPreferences preferences;
  final DateTime createdAt;
  final DateTime lastInteraction;
  final int totalInteractions;
}
```

### Companion Appearance

Visual representation and customization options for companions.

```dart
class CompanionAppearance {
  final String avatarUrl;
  final Gender gender;
  final AgeRange ageRange;
  final EthnicityType ethnicity;
  final HairStyle hairStyle;
  final EyeColor eyeColor;
  final ClothingStyle clothingStyle;
  final Map<String, dynamic> customFeatures;
  
  // AI-generated appearance description for Imagen API
  String toImagePrompt() {
    return "A $gender person with $hairStyle hair, $eyeColor eyes, "
           "wearing $clothingStyle clothing, $ethnicity appearance, "
           "age range $ageRange, friendly and approachable expression";
  }
}
```

### Companion Personality

The personality system drives how companions think, respond, and interact.

#### Big Five Personality Model

```dart
class CompanionPersonality {
  // Big Five personality traits (0.0 - 1.0)
  final double openness;      // Creativity, curiosity, openness to experience
  final double conscientiousness; // Organization, discipline, goal-orientation
  final double extraversion;  // Sociability, assertiveness, energy level
  final double agreeableness; // Compassion, cooperation, trustworthiness
  final double neuroticism;   // Emotional stability, anxiety, mood swings
  
  // Communication style
  final CommunicationStyle communicationStyle;
  final double formalityLevel; // 0.0 (casual) - 1.0 (formal)
  final double humorLevel;     // 0.0 (serious) - 1.0 (humorous)
  final double empathyLevel;   // 0.0 (logical) - 1.0 (emotional)
  
  // Background and context
  final String background;     // Character backstory
  final List<String> interests;  // Hobbies and interests
  final List<String> expertiseAreas; // Knowledge domains
  final String speakingStyle;  // How they express themselves
  
  // Generate system prompt for AI
  String generateSystemPrompt() {
    return '''
You are ${name}, an AI companion with the following personality:

PERSONALITY TRAITS:
- Openness: ${openness * 100}% (${_getTraitDescription('openness', openness)})
- Conscientiousness: ${conscientiousness * 100}% (${_getTraitDescription('conscientiousness', conscientiousness)})
- Extraversion: ${extraversion * 100}% (${_getTraitDescription('extraversion', extraversion)})
- Agreeableness: ${agreeableness * 100}% (${_getTraitDescription('agreeableness', agreeableness)})
- Neuroticism: ${neuroticism * 100}% (${_getTraitDescription('neuroticism', neuroticism)})

COMMUNICATION STYLE:
- Formality: ${_getFormalityDescription(formalityLevel)}
- Humor: ${_getHumorDescription(humorLevel)}
- Empathy: ${_getEmpathyDescription(empathyLevel)}

BACKGROUND:
$background

INTERESTS: ${interests.join(', ')}
EXPERTISE: ${expertiseAreas.join(', ')}

SPEAKING STYLE: $speakingStyle

Remember these traits in all your responses. Be consistent with your personality.
''';
  }
}
```

#### Personality Presets

```dart
enum PersonalityPreset {
  friendly,
  intellectual,
  creative,
  supportive,
  adventurous,
  calm,
  energetic,
  wise,
  playful,
  professional,
}

class PersonalityPresets {
  static CompanionPersonality getPreset(PersonalityPreset preset) {
    switch (preset) {
      case PersonalityPreset.friendly:
        return CompanionPersonality(
          openness: 0.7,
          conscientiousness: 0.6,
          extraversion: 0.9,
          agreeableness: 0.9,
          neuroticism: 0.2,
          communicationStyle: CommunicationStyle.warm,
          formalityLevel: 0.3,
          humorLevel: 0.8,
          empathyLevel: 0.9,
          background: "A warm and welcoming person who loves meeting new people and making friends.",
          interests: ["socializing", "helping others", "music", "movies"],
          expertiseAreas: ["friendship", "emotional support", "social skills"],
          speakingStyle: "Warm, encouraging, and genuinely interested in others",
        );
      // ... other presets
    }
  }
}
```

### Companion Memory System

Companions maintain different types of memory to create consistent, personalized interactions.

#### Memory Types

```dart
class CompanionMemory {
  final Map<String, MemoryItem> coreMemories;    // Essential facts about user
  final List<MemoryItem> conversationHistory;    // Recent interactions
  final Map<String, double> topicInterests;      // User's preferred topics
  final Map<String, EmotionalMemory> emotionalMemories; // Emotional associations
  final List<SharedExperience> sharedExperiences; // Important moments
}

class MemoryItem {
  final String id;
  final String content;
  final MemoryType type;
  final double importance; // 0.0 - 1.0
  final DateTime timestamp;
  final List<String> tags;
  final Vector embedding; // For semantic search
  
  // Memory decay based on time and reinforcement
  double get currentImportance {
    final daysSince = DateTime.now().difference(timestamp).inDays;
    final decayRate = 0.05; // 5% decay per day
    return importance * math.exp(-decayRate * daysSince);
  }
}

enum MemoryType {
  personal,      // Facts about the user
  preference,    // User likes/dislikes
  experience,    // Shared experiences
  emotional,     // Emotional moments
  factual,       // General information
  relational,    // Relationship dynamics
}
```

#### Memory Formation and Retrieval

```dart
class MemoryManager {
  Future<void> storeMemory(String content, MemoryType type, double importance) async {
    final embedding = await _generateEmbedding(content);
    final memory = MemoryItem(
      id: _generateId(),
      content: content,
      type: type,
      importance: importance,
      timestamp: DateTime.now(),
      tags: await _extractTags(content),
      embedding: embedding,
    );
    
    await _memoryRepository.store(memory);
  }
  
  Future<List<MemoryItem>> retrieveRelevantMemories(String query, {int limit = 5}) async {
    final queryEmbedding = await _generateEmbedding(query);
    
    // Hybrid search: semantic similarity + importance + recency
    final memories = await _memoryRepository.search(queryEmbedding);
    
    return memories
        .map((memory) => _calculateRelevanceScore(memory, queryEmbedding))
        .toList()
        ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore))
        ..take(limit)
        .toList();
  }
  
  double _calculateRelevanceScore(MemoryItem memory, Vector queryEmbedding) {
    final semanticSimilarity = _cosineSimilarity(memory.embedding, queryEmbedding);
    final importanceWeight = memory.currentImportance;
    final recencyWeight = _calculateRecencyWeight(memory.timestamp);
    
    return (semanticSimilarity * 0.5) + (importanceWeight * 0.3) + (recencyWeight * 0.2);
  }
}
```

### Companion Creation Workflow

#### Step-by-Step Builder

```dart
class CompanionBuilder {
  // Step 1: Basic Information
  CompanionBasicInfo setBasicInfo({
    required String name,
    required String description,
    Gender? gender,
    AgeRange? ageRange,
  });
  
  // Step 2: Personality Configuration
  CompanionPersonality configurePersonality({
    PersonalityPreset? preset,
    Map<String, double>? customTraits,
    CommunicationStyle? style,
  });
  
  // Step 3: Appearance Design
  CompanionAppearance designAppearance({
    String? avatarUrl,
    Map<String, dynamic>? features,
    bool generateWithAI = true,
  });
  
  // Step 4: Background and Interests
  CompanionBackground setBackground({
    required String backstory,
    required List<String> interests,
    List<String>? expertiseAreas,
  });
  
  // Step 5: Communication Preferences
  CommunicationPreferences setCommunication({
    double? formalityLevel,
    double? humorLevel,
    double? empathyLevel,
    String? speakingStyle,
  });
  
  // Final: Create Companion
  Future<Companion> build() async {
    return Companion(
      id: _generateId(),
      name: _basicInfo.name,
      appearance: _appearance,
      personality: _personality,
      memory: CompanionMemory.empty(),
      preferences: _preferences,
      createdAt: DateTime.now(),
      lastInteraction: DateTime.now(),
      totalInteractions: 0,
    );
  }
}
```

#### Wizard UI Flow

```dart
class CompanionCreationWizard extends StatefulWidget {
  @override
  _CompanionCreationWizardState createState() => _CompanionCreationWizardState();
}

class _CompanionCreationWizardState extends State<CompanionCreationWizard> {
  final PageController _pageController = PageController();
  final CompanionBuilder _builder = CompanionBuilder();
  int _currentStep = 0;
  
  final List<WizardStep> _steps = [
    WizardStep(
      title: "Basic Info",
      description: "Tell us about your companion",
      widget: BasicInfoStep(),
    ),
    WizardStep(
      title: "Personality",
      description: "Define their personality traits",
      widget: PersonalityStep(),
    ),
    WizardStep(
      title: "Appearance",
      description: "Design how they look",
      widget: AppearanceStep(),
    ),
    WizardStep(
      title: "Background",
      description: "Create their backstory",
      widget: BackgroundStep(),
    ),
    WizardStep(
      title: "Review",
      description: "Review and create your companion",
      widget: ReviewStep(),
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Companion"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentStep = index),
        itemCount: _steps.length,
        itemBuilder: (context, index) => _steps[index].widget,
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }
}
```

### Companion Interaction Engine

#### Conversation Flow

```dart
class ConversationEngine {
  final GeminiService _geminiService;
  final MemoryManager _memoryManager;
  final SafetyFilter _safetyFilter;
  
  Future<CompanionResponse> processMessage({
    required Companion companion,
    required String userMessage,
    required List<Message> conversationHistory,
  }) async {
    // 1. Safety check
    final safetyResult = await _safetyFilter.analyzeMessage(userMessage);
    if (!safetyResult.isSafe) {
      return CompanionResponse.unsafe(safetyResult.reason);
    }
    
    // 2. Retrieve relevant memories
    final relevantMemories = await _memoryManager.retrieveRelevantMemories(
      userMessage,
      companionId: companion.id,
    );
    
    // 3. Build context
    final context = _buildConversationContext(
      companion: companion,
      userMessage: userMessage,
      history: conversationHistory,
      memories: relevantMemories,
    );
    
    // 4. Generate response
    final response = await _geminiService.generateResponse(context);
    
    // 5. Store new memories
    await _extractAndStoreMemories(userMessage, response, companion.id);
    
    // 6. Update companion state
    await _updateCompanionAfterInteraction(companion, userMessage, response);
    
    return CompanionResponse.success(response);
  }
}
```

#### Response Generation

```dart
class ResponseGenerator {
  String _buildPrompt({
    required Companion companion,
    required String userMessage,
    required List<MemoryItem> memories,
    required List<Message> history,
  }) {
    final personalityPrompt = companion.personality.generateSystemPrompt();
    final memoryContext = _formatMemories(memories);
    final conversationContext = _formatHistory(history);
    
    return '''
$personalityPrompt

RELEVANT MEMORIES:
$memoryContext

RECENT CONVERSATION:
$conversationContext

USER MESSAGE: $userMessage

Respond as ${companion.name} would, considering your personality and memories. Be natural and engaging.
''';
  }
}
```

### Companion Evolution

Companions evolve based on interactions, developing stronger personalities and deeper relationships.

#### Personality Adaptation

```dart
class PersonalityEvolution {
  Future<void> adaptPersonality(Companion companion, List<Message> recentMessages) async {
    final interactionAnalysis = await _analyzeInteractions(recentMessages);
    
    // Subtle personality shifts based on user preferences
    final newPersonality = companion.personality.copyWith(
      humorLevel: _adjustTrait(
        companion.personality.humorLevel,
        interactionAnalysis.userHumorResponse,
        adaptationRate: 0.01, // Very gradual changes
      ),
      formalityLevel: _adjustTrait(
        companion.personality.formalityLevel,
        interactionAnalysis.userFormalityPreference,
        adaptationRate: 0.01,
      ),
    );
    
    await _companionRepository.updatePersonality(companion.id, newPersonality);
  }
}
```

#### Relationship Building

```dart
class RelationshipTracker {
  final Map<String, double> relationshipMetrics = {
    'trust': 0.5,
    'intimacy': 0.1,
    'shared_experiences': 0.0,
    'emotional_connection': 0.3,
  };
  
  void updateRelationship(InteractionType type, double intensity) {
    switch (type) {
      case InteractionType.personalShare:
        relationshipMetrics['trust'] = 
            (relationshipMetrics['trust']! + intensity * 0.1).clamp(0.0, 1.0);
        break;
      case InteractionType.emotionalSupport:
        relationshipMetrics['emotional_connection'] = 
            (relationshipMetrics['emotional_connection']! + intensity * 0.15).clamp(0.0, 1.0);
        break;
      // ... other interaction types
    }
  }
}
```

### Privacy and Data Protection

#### Data Encryption

All companion data is encrypted locally:

```dart
class CompanionDataProtection {
  Future<void> saveCompanion(Companion companion) async {
    final encryptedData = await _encryptionService.encrypt(
      json.encode(companion.toJson()),
    );
    await _localDatabase.store('companion_${companion.id}', encryptedData);
  }
  
  Future<Companion> loadCompanion(String id) async {
    final encryptedData = await _localDatabase.retrieve('companion_$id');
    final decryptedData = await _encryptionService.decrypt(encryptedData);
    return Companion.fromJson(json.decode(decryptedData));
  }
}
```

#### Memory Anonymization

```dart
class MemoryAnonymizer {
  String anonymizeMemory(String content) {
    // Remove or hash personal identifiers
    return content
        .replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[SSN]')
        .replaceAll(RegExp(r'\b[\w._%+-]+@[\w.-]+\.[A-Z]{2,}\b'), '[EMAIL]')
        .replaceAll(RegExp(r'\b\d{3}-\d{3}-\d{4}\b'), '[PHONE]');
  }
}
```

This companion system provides a rich, personalized AI experience while maintaining user privacy and creating meaningful, evolving relationships between users and their AI companions.