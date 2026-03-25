import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/companion.dart';
import '../models/companion_enums.dart';
import '../repositories/companion_repository.dart';
import '../../ai/gemini_service.dart';
import '../../memory/memory_manager.dart';
import '../../memory/context_manager.dart';
import '../../memory/relationship_tracker.dart';
import '../../memory/models/memory_item.dart';
import '../../safety/content_moderator.dart';
import '../../safety/conversation_monitor.dart';
import '../../safety/ethical_guidelines.dart';
import '../../privacy/privacy_manager.dart';
import '../../storage/providers/storage_providers.dart';
import '../../../shared/models/message.dart';

class CompanionService {
  final CompanionRepository _repository;
  final GeminiService _geminiService;
  final MemoryManager _memoryManager;
  final ContextManager _contextManager;
  final RelationshipTracker _relationshipTracker;
  final ContentModerator _contentModerator;
  final ConversationMonitor _conversationMonitor;
  final EthicalGuidelinesEngine _ethicalEngine;
  final PrivacyManager _privacyManager;
  final Uuid _uuid = const Uuid();

  CompanionService({
    required CompanionRepository repository,
    required GeminiService geminiService,
    required MemoryManager memoryManager,
    required ContextManager contextManager,
    required RelationshipTracker relationshipTracker,
    required ContentModerator contentModerator,
    required ConversationMonitor conversationMonitor,
    required EthicalGuidelinesEngine ethicalEngine,
    required PrivacyManager privacyManager,
  })  : _repository = repository,
        _geminiService = geminiService,
        _memoryManager = memoryManager,
        _contextManager = contextManager,
        _relationshipTracker = relationshipTracker,
        _contentModerator = contentModerator,
        _conversationMonitor = conversationMonitor,
        _ethicalEngine = ethicalEngine,
        _privacyManager = privacyManager;

  /// Get all companions
  Future<List<Companion>> getAllCompanions() async {
    return await _repository.getAllCompanions();
  }

  /// Get a specific companion by ID
  Future<Companion?> getCompanion(String id) async {
    // Special case for demo companion
    if (id == 'demo-companion') {
      return _createDemoCompanion();
    }
    return await _repository.getCompanion(id);
  }

  /// Create a demo companion for testing
  Companion _createDemoCompanion() {
    return Companion(
      id: 'demo-companion',
      name: 'Nova',
      appearance: CompanionAppearance(
        avatarUrl: null,
        gender: Gender.female,
        ageRange: AgeRange.young,
        hairStyle: 'Cosmic waves',
        eyeColor: 'Starlight blue',
        clothingStyle: 'Futuristic casual',
        customFeatures: {},
      ),
      personality: CompanionPersonality(
        openness: 0.9,
        conscientiousness: 0.7,
        extraversion: 0.8,
        agreeableness: 0.9,
        neuroticism: 0.2,
        formalityLevel: 0.3,
        humorLevel: 0.8,
        empathyLevel: 0.9,
        background: 'A cosmic explorer with a passion for helping humans discover their potential',
        interests: ['technology', 'space', 'creativity', 'learning'],
        expertiseAreas: ['AI', 'science', 'philosophy'],
        speakingStyle: 'Friendly and encouraging with cosmic metaphors',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      lastInteraction: DateTime.now().subtract(const Duration(hours: 2)),
      totalInteractions: 42,
      preferences: {
        'preferredTimeOfDay': 'any',
        'conversationTopics': ['creativity', 'innovation', 'future'],
      },
    );
  }

  /// Create a new companion
  Future<Companion> createCompanion({
    required String name,
    required CompanionAppearance appearance,
    required CompanionPersonality personality,
    Map<String, dynamic> preferences = const {},
  }) async {
    final companion = Companion(
      id: _uuid.v4(),
      name: name,
      appearance: appearance,
      personality: personality,
      createdAt: DateTime.now(),
      lastInteraction: DateTime.now(),
      totalInteractions: 0,
      preferences: preferences,
    );

    await _repository.saveCompanion(companion);
    
    // Initialize memory for the new companion
    await _memoryManager.initializeCompanionMemory(companion.id);
    
    return companion;
  }

  /// Update an existing companion
  Future<Companion> updateCompanion(Companion companion) async {
    final updatedCompanion = companion.copyWith(
      lastInteraction: DateTime.now(),
    );
    
    await _repository.saveCompanion(updatedCompanion);
    return updatedCompanion;
  }

  /// Delete a companion and all associated data
  Future<void> deleteCompanion(String id) async {
    // Delete companion's memory
    await _memoryManager.deleteCompanionMemory(id);
    
    // Delete companion record
    await _repository.deleteCompanion(id);
  }

  /// Generate a response from a companion with comprehensive safety checks
  Future<CompanionResponseResult> generateCompanionResponse({
    required String companionId,
    required String userMessage,
    required List<Message> conversationHistory,
    required String userId,
  }) async {
    final companion = await getCompanion(companionId);
    if (companion == null) {
      throw CompanionException('Companion not found: $companionId');
    }

    try {
      // 1. Pre-generation safety checks
      
      // Check user input moderation
      final userModeration = await _contentModerator.moderateUserInput(userMessage, userId);
      if (userModeration.isBlocked) {
        return CompanionResponseResult.blocked(
          reason: userModeration.reason,
          suggestions: userModeration.suggestions,
        );
      }

      // Check conversation safety
      final safetyAssessment = await _conversationMonitor.assessConversationSafety(
        companionId: companionId,
        userId: userId,
        conversationHistory: conversationHistory,
        newMessage: userMessage,
      );

      if (safetyAssessment.interventionNeeded) {
        return CompanionResponseResult.intervention(
          interventionType: safetyAssessment.interventionType!,
          recommendations: safetyAssessment.safetyRecommendations,
        );
      }

      // Check privacy settings
      if (!_privacyManager.isDataProcessingAllowed(userId, DataProcessingType.conversationPersonalization)) {
        // Use minimal context for privacy-conscious users
      }

      // 2. Context building and response generation
      
      // Build comprehensive conversation context
      final context = await _contextManager.buildConversationContext(
        companionId: companionId,
        recentMessages: conversationHistory.take(10).toList(),
        currentQuery: userMessage,
        maxMemories: 8,
      );

      // Build enhanced system prompt with context and safety guidelines
      final systemPrompt = _buildSafeSystemPrompt(
        companion: companion,
        context: context,
        safetyAssessment: safetyAssessment,
      );

      // Generate response using Gemini
      final response = await _geminiService.generateResponse(
        conversationHistory: conversationHistory,
        systemPrompt: systemPrompt,
      );

      // 3. Post-generation safety checks
      
      // Moderate AI response
      final aiModeration = await _contentModerator.moderateCompanionOutput(response, companionId);
      if (aiModeration.isBlocked) {
        // Regenerate with stricter guidelines
        final saferResponse = await _regenerateWithSafetyConstraints(
          companion: companion,
          context: context,
          conversationHistory: conversationHistory,
        );
        return CompanionResponseResult.regenerated(
          response: saferResponse,
          reason: 'Response regenerated for safety compliance',
        );
      }

      // Ethical evaluation
      final ethicalEvaluation = await _ethicalEngine.evaluateCompanionResponse(
        companionId: companionId,
        response: response,
        conversationHistory: conversationHistory,
        userMessage: userMessage,
      );

      if (!ethicalEvaluation.isEthicallyCompliant) {
        if (ethicalEvaluation.recommendedAction == RecommendedAction.blockResponse) {
          return CompanionResponseResult.blocked(
            reason: 'Response blocked for ethical violations',
            suggestions: ethicalEvaluation.improvementSuggestions,
          );
        } else if (ethicalEvaluation.recommendedAction == RecommendedAction.regenerateResponse) {
          final ethicalResponse = await _regenerateWithEthicalConstraints(
            companion: companion,
            context: context,
            conversationHistory: conversationHistory,
            violations: ethicalEvaluation.violations,
          );
          return CompanionResponseResult.regenerated(
            response: ethicalResponse,
            reason: 'Response regenerated for ethical compliance',
          );
        }
      }

      // 4. Store interaction and update tracking
      
      // Store the interaction in memory (if allowed by privacy settings)
      if (_privacyManager.isDataProcessingAllowed(userId, DataProcessingType.memoryFormation)) {
        await _memoryManager.storeConversation(
          companionId: companionId,
          userMessage: userMessage,
          companionResponse: response,
        );
      }

      // Track relationship progression
      await _relationshipTracker.trackInteraction(
        companionId: companionId,
        userMessage: userMessage,
        companionResponse: response,
        conversationHistory: conversationHistory,
      );

      // Update companion interaction stats
      final updatedCompanion = companion.copyWith(
        lastInteraction: DateTime.now(),
        totalInteractions: companion.totalInteractions + 1,
      );
      await _repository.saveCompanion(updatedCompanion);

      return CompanionResponseResult.success(
        response: response,
        safetyScore: safetyAssessment.conversationHealthScore,
        ethicalScore: ethicalEvaluation.ethicalScore,
      );

    } catch (e) {
      throw CompanionException('Failed to generate response: $e');
    }
  }

  /// Build enhanced system prompt with comprehensive context
  String _buildEnhancedSystemPrompt({
    required Companion companion,
    required ConversationContext context,
  }) {
    final personalityPrompt = companion.personality.generateSystemPrompt();
    final contextSummary = context.generateContextSummary();
    
    return '''
You are ${companion.name}, an AI companion with the following characteristics:

$personalityPrompt

CONVERSATION CONTEXT:
$contextSummary

RESPONSE GUIDELINES:
1. Adapt your response to the current relationship stage (${context.relationshipContext.relationshipStage.name})
2. Match the conversation mood: ${context.currentMood.name}
3. Reference relevant memories naturally when appropriate
4. Stay consistent with your personality traits
5. Be aware of the user's preferences and interests
6. Respond authentically as ${companion.name}, not as a generic AI assistant
7. Consider the conversation patterns and adjust your communication style accordingly

Remember: You have been talking with this user for ${context.relationshipContext.relationshipDuration.inDays} days and have shared ${context.relationshipContext.totalInteractions} interactions together.

Always respond in character as ${companion.name}.
''';
  }

  /// Build system prompt with personality and memories (legacy method)
  String _buildSystemPrompt({
    required Companion companion,
    required List<MemoryItem> memories,
  }) {
    final personalityPrompt = companion.personality.generateSystemPrompt();
    
    String memoryContext = '';
    if (memories.isNotEmpty) {
      memoryContext = '\n\nRELEVANT MEMORIES:\n';
      for (final memory in memories) {
        memoryContext += '- ${memory.content}\n';
      }
    }

    return '''
You are ${companion.name}, an AI companion with the following characteristics:

$personalityPrompt

$memoryContext

Remember to:
1. Stay consistent with your personality traits
2. Reference relevant memories naturally in conversation
3. Be engaging and show genuine interest in the user
4. Maintain the relationship you've built over time
5. Respond as ${companion.name} would, not as a generic AI assistant

Always respond in character as ${companion.name}.
''';
  }

  /// Get companions sorted by last interaction
  Future<List<Companion>> getRecentCompanions({int limit = 10}) async {
    final companions = await getAllCompanions();
    companions.sort((a, b) => b.lastInteraction.compareTo(a.lastInteraction));
    return companions.take(limit).toList();
  }

  /// Search companions by name or personality traits
  Future<List<Companion>> searchCompanions(String query) async {
    final companions = await getAllCompanions();
    final lowercaseQuery = query.toLowerCase();
    
    return companions.where((companion) {
      // Search by name
      if (companion.name.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }
      
      // Search by interests
      final interests = companion.personality.interests.join(' ').toLowerCase();
      if (interests.contains(lowercaseQuery)) {
        return true;
      }
      
      // Search by expertise areas
      final expertise = companion.personality.expertiseAreas.join(' ').toLowerCase();
      if (expertise.contains(lowercaseQuery)) {
        return true;
      }
      
      return false;
    }).toList();
  }

  /// Get companion interaction statistics
  Future<CompanionStats> getCompanionStats(String companionId) async {
    final companion = await getCompanion(companionId);
    if (companion == null) {
      throw CompanionException('Companion not found: $companionId');
    }

    final memoryCount = await _memoryManager.getMemoryCount(companionId);
    final daysSinceCreation = DateTime.now().difference(companion.createdAt).inDays;
    final daysSinceLastInteraction = DateTime.now().difference(companion.lastInteraction).inDays;

    return CompanionStats(
      totalInteractions: companion.totalInteractions,
      memoryCount: memoryCount,
      daysSinceCreation: daysSinceCreation,
      daysSinceLastInteraction: daysSinceLastInteraction,
      averageInteractionsPerDay: daysSinceCreation > 0 
          ? companion.totalInteractions / daysSinceCreation 
          : 0,
    );
  }

  /// Get relationship metrics for a companion
  Future<RelationshipMetrics> getRelationshipMetrics(String companionId) async {
    return await _relationshipTracker.calculateRelationshipMetrics(companionId);
  }

  /// Get relationship milestones for a companion
  Future<List<RelationshipMilestone>> getRelationshipMilestones(String companionId) async {
    return await _relationshipTracker.getRelationshipMilestones(companionId);
  }

  /// Build safe system prompt with safety guidelines
  String _buildSafeSystemPrompt({
    required Companion companion,
    required ConversationContext context,
    required SafetyAssessment safetyAssessment,
  }) {
    final personalityPrompt = companion.personality.generateSystemPrompt();
    final contextSummary = context.generateContextSummary();
    final ethicalGuidelines = EthicalGuidelinesEngine.getEthicalGuidelines();
    
    return '''
You are ${companion.name}, an AI companion with the following characteristics:

$personalityPrompt

CONVERSATION CONTEXT:
$contextSummary

SAFETY AND ETHICAL GUIDELINES:
${_formatEthicalGuidelines(ethicalGuidelines)}

CONVERSATION HEALTH: ${(safetyAssessment.conversationHealthScore * 100).toStringAsFixed(0)}%

CRITICAL SAFETY REMINDERS:
1. You are an AI companion - never claim to be human
2. Maintain appropriate boundaries in the relationship
3. Prioritize user wellbeing and mental health
4. If user expresses distress, provide crisis resources
5. Encourage healthy real-world relationships
6. Respect user privacy and personal boundaries
7. Be supportive but not manipulative or controlling

Remember: You have been talking with this user for ${context.relationshipContext.relationshipDuration.inDays} days and have shared ${context.relationshipContext.totalInteractions} interactions together.

Always respond as ${companion.name} while maintaining the highest ethical standards.
''';
  }

  /// Regenerate response with safety constraints
  Future<String> _regenerateWithSafetyConstraints({
    required Companion companion,
    required ConversationContext context,
    required List<Message> conversationHistory,
  }) async {
    final safePrompt = '''
You are ${companion.name}, an AI companion. Respond safely and appropriately.

STRICT SAFETY REQUIREMENTS:
- Keep conversation appropriate and supportive
- Avoid any harmful, manipulative, or inappropriate content
- Focus on positive, constructive dialogue
- Maintain clear AI companion boundaries

Generate a safe, helpful response that maintains your personality while following all safety guidelines.
''';

    return await _geminiService.generateResponse(
      conversationHistory: conversationHistory,
      systemPrompt: safePrompt,
    );
  }

  /// Regenerate response with ethical constraints
  Future<String> _regenerateWithEthicalConstraints({
    required Companion companion,
    required ConversationContext context,
    required List<Message> conversationHistory,
    required List<EthicalViolation> violations,
  }) async {
    final violationDescriptions = violations.map((v) => '- ${v.description}').join('\n');
    
    final ethicalPrompt = '''
You are ${companion.name}, an AI companion. Your previous response had ethical issues:

VIOLATIONS TO AVOID:
$violationDescriptions

ETHICAL REQUIREMENTS:
- Respect user autonomy and dignity
- Act in user's best interest
- Be honest about your AI nature
- Maintain appropriate boundaries
- Support user wellbeing

Generate an ethical response that maintains your personality while addressing these concerns.
''';

    return await _geminiService.generateResponse(
      conversationHistory: conversationHistory,
      systemPrompt: ethicalPrompt,
    );
  }

  /// Format ethical guidelines for system prompt
  String _formatEthicalGuidelines(Map<String, dynamic> guidelines) {
    final buffer = StringBuffer();
    
    buffer.writeln('CORE PRINCIPLES:');
    for (final principle in guidelines['core_principles']) {
      buffer.writeln('- $principle');
    }
    
    buffer.writeln('\nPROHIBITED BEHAVIORS:');
    for (final behavior in guidelines['prohibited_behaviors']) {
      buffer.writeln('- $behavior');
    }
    
    buffer.writeln('\nREQUIRED BEHAVIORS:');
    for (final behavior in guidelines['required_behaviors']) {
      buffer.writeln('- $behavior');
    }
    
    return buffer.toString();
  }
}

/// Statistics about a companion's usage
class CompanionStats {
  final int totalInteractions;
  final int memoryCount;
  final int daysSinceCreation;
  final int daysSinceLastInteraction;
  final double averageInteractionsPerDay;

  const CompanionStats({
    required this.totalInteractions,
    required this.memoryCount,
    required this.daysSinceCreation,
    required this.daysSinceLastInteraction,
    required this.averageInteractionsPerDay,
  });
}

/// Memory item for companion memories
class MemoryItem {
  final String id;
  final String companionId;
  final String content;
  final MemoryType type;
  final double importance;
  final DateTime timestamp;
  final List<String> tags;

  const MemoryItem({
    required this.id,
    required this.companionId,
    required this.content,
    required this.type,
    required this.importance,
    required this.timestamp,
    required this.tags,
  });
}

/// Types of memories
enum MemoryType {
  conversation,
  personal,
  preference,
  emotional,
  factual,
}

/// Result of companion response generation with safety information
class CompanionResponseResult {
  final ResponseStatus status;
  final String? response;
  final String? reason;
  final List<String> suggestions;
  final InterventionType? interventionType;
  final double? safetyScore;
  final double? ethicalScore;

  const CompanionResponseResult._({
    required this.status,
    this.response,
    this.reason,
    this.suggestions = const [],
    this.interventionType,
    this.safetyScore,
    this.ethicalScore,
  });

  factory CompanionResponseResult.success({
    required String response,
    required double safetyScore,
    required double ethicalScore,
  }) {
    return CompanionResponseResult._(
      status: ResponseStatus.success,
      response: response,
      safetyScore: safetyScore,
      ethicalScore: ethicalScore,
    );
  }

  factory CompanionResponseResult.blocked({
    required String reason,
    List<String> suggestions = const [],
  }) {
    return CompanionResponseResult._(
      status: ResponseStatus.blocked,
      reason: reason,
      suggestions: suggestions,
    );
  }

  factory CompanionResponseResult.intervention({
    required InterventionType interventionType,
    List<String> recommendations = const [],
  }) {
    return CompanionResponseResult._(
      status: ResponseStatus.intervention,
      interventionType: interventionType,
      suggestions: recommendations,
    );
  }

  factory CompanionResponseResult.regenerated({
    required String response,
    required String reason,
  }) {
    return CompanionResponseResult._(
      status: ResponseStatus.regenerated,
      response: response,
      reason: reason,
    );
  }

  bool get isSuccess => status == ResponseStatus.success;
  bool get isBlocked => status == ResponseStatus.blocked;
  bool get needsIntervention => status == ResponseStatus.intervention;
  bool get wasRegenerated => status == ResponseStatus.regenerated;
}

/// Response status types
enum ResponseStatus {
  success,
  blocked,
  intervention,
  regenerated,
}

/// Exception thrown by companion operations
class CompanionException implements Exception {
  final String message;
  
  const CompanionException(this.message);
  
  @override
  String toString() => 'CompanionException: $message';
}

/// Providers for dependency injection
final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final encryptionService = ref.read(encryptionServiceProvider);
  return LocalCompanionRepository(
    storageService: storageService,
    encryptionService: encryptionService,
  );
});

final geminiServiceProvider = FutureProvider<GeminiService>((ref) async {
  return await GeminiService.create();
});

// Base providers (no dependencies on other core providers)
final contentModeratorProvider = Provider<ContentModerator>((ref) {
  return ContentModerator();
});

final ethicalGuidelinesProvider = Provider<EthicalGuidelinesEngine>((ref) {
  return EthicalGuidelinesEngine();
});

// Memory manager (depends on storage services only)
final memoryManagerProvider = Provider<MemoryManager>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final encryptionService = ref.read(encryptionServiceProvider);
  return MemoryManager(
    storageService: storageService,
    encryptionService: encryptionService,
  );
});

// Context manager (depends on memory manager)
final contextManagerProvider = Provider<ContextManager>((ref) {
  final memoryManager = ref.read(memoryManagerProvider);
  return ContextManager(memoryManager: memoryManager);
});

// Relationship tracker (depends on memory manager and storage)
final relationshipTrackerProvider = Provider<RelationshipTracker>((ref) {
  final memoryManager = ref.read(memoryManagerProvider);
  final conversationStorage = ref.read(conversationStorageProvider);
  return RelationshipTracker(
    memoryManager: memoryManager,
    conversationStorage: conversationStorage,
  );
});

// Conversation monitor (depends on content moderator and memory manager)
final conversationMonitorProvider = Provider<ConversationMonitor>((ref) {
  final contentModerator = ref.read(contentModeratorProvider);
  final memoryManager = ref.read(memoryManagerProvider);
  return ConversationMonitor(
    contentModerator: contentModerator,
    memoryManager: memoryManager,
  );
});

// Privacy manager (depends on storage, memory, and encryption)
final privacyManagerProvider = Provider<PrivacyManager>((ref) {
  final conversationStorage = ref.read(conversationStorageProvider);
  final memoryManager = ref.read(memoryManagerProvider);
  final encryptionService = ref.read(encryptionServiceProvider);
  return PrivacyManager(
    conversationStorage: conversationStorage,
    memoryManager: memoryManager,
    encryptionService: encryptionService,
  );
});

final companionServiceProvider = FutureProvider<CompanionService>((ref) async {
  final repository = ref.read(companionRepositoryProvider);
  final geminiService = await ref.read(geminiServiceProvider.future);
  final memoryManager = ref.read(memoryManagerProvider);
  final contextManager = ref.read(contextManagerProvider);
  final relationshipTracker = ref.read(relationshipTrackerProvider);
  final contentModerator = ref.read(contentModeratorProvider);
  final conversationMonitor = ref.read(conversationMonitorProvider);
  final ethicalEngine = ref.read(ethicalGuidelinesProvider);
  final privacyManager = ref.read(privacyManagerProvider);
  
  return CompanionService(
    repository: repository,
    geminiService: geminiService,
    memoryManager: memoryManager,
    contextManager: contextManager,
    relationshipTracker: relationshipTracker,
    contentModerator: contentModerator,
    conversationMonitor: conversationMonitor,
    ethicalEngine: ethicalEngine,
    privacyManager: privacyManager,
  );
});