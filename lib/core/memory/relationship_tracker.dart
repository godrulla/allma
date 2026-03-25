import 'dart:math' as math;

import 'memory_manager.dart';
import 'models/memory_item.dart';
import '../../shared/models/message.dart';
import '../storage/conversation_storage.dart';

/// Tracks and manages relationship progression between user and companion
class RelationshipTracker {
  final MemoryManager _memoryManager;
  final ConversationStorage _conversationStorage;

  RelationshipTracker({
    required MemoryManager memoryManager,
    required ConversationStorage conversationStorage,
  })  : _memoryManager = memoryManager,
        _conversationStorage = conversationStorage;

  /// Calculate current relationship metrics
  Future<RelationshipMetrics> calculateRelationshipMetrics(String companionId) async {
    final memories = await _memoryManager.getCompanionMemories(companionId);
    final stats = await _conversationStorage.getConversationStats(companionId);
    
    // Calculate various relationship dimensions
    final intimacy = await _calculateIntimacyLevel(companionId, memories);
    final trust = await _calculateTrustLevel(companionId, memories, stats);
    final engagement = await _calculateEngagementLevel(companionId, stats);
    final emotional = await _calculateEmotionalBond(companionId, memories);
    final consistency = await _calculateConsistencyScore(companionId, stats);

    // Determine overall relationship stage
    final stage = _determineRelationshipStage(intimacy, trust, engagement, emotional);
    
    // Calculate relationship health
    final health = _calculateRelationshipHealth(intimacy, trust, engagement, emotional, consistency);

    return RelationshipMetrics(
      intimacyLevel: intimacy,
      trustLevel: trust,
      engagementLevel: engagement,
      emotionalBond: emotional,
      consistencyScore: consistency,
      relationshipStage: stage,
      relationshipHealth: health,
      totalInteractions: stats.totalMessages,
      relationshipDuration: stats.conversationDuration ?? Duration.zero,
      lastInteraction: stats.lastMessageAt,
    );
  }

  /// Track relationship progression after each interaction
  Future<void> trackInteraction({
    required String companionId,
    required String userMessage,
    required String companionResponse,
    required List<Message> conversationHistory,
  }) async {
    // Analyze interaction quality
    final interactionAnalysis = _analyzeInteraction(
      userMessage: userMessage,
      companionResponse: companionResponse,
      conversationHistory: conversationHistory,
    );

    // Store relationship milestone if significant
    if (interactionAnalysis.isSignificant) {
      await _storeMilestone(companionId, interactionAnalysis);
    }

    // Update relationship progression
    await _updateRelationshipProgression(companionId, interactionAnalysis);
  }

  /// Calculate intimacy level based on personal information shared
  Future<double> _calculateIntimacyLevel(String companionId, List<MemoryItem> memories) async {
    final personalMemories = memories.where((m) => m.isPersonalInfo).toList();
    
    if (memories.isEmpty) return 0.0;
    
    // Base intimacy from personal information ratio
    double intimacy = (personalMemories.length / memories.length) * 100;
    
    // Boost for high-importance personal memories
    final highImportancePersonal = personalMemories.where((m) => m.importance > 0.8).length;
    intimacy += (highImportancePersonal * 10);
    
    // Consider recency of personal sharing
    final recentPersonal = personalMemories.where((m) => 
      DateTime.now().difference(m.timestamp).inDays < 7
    ).length;
    intimacy += (recentPersonal * 5);
    
    return math.min(100.0, intimacy);
  }

  /// Calculate trust level based on conversation consistency and depth
  Future<double> _calculateTrustLevel(String companionId, List<MemoryItem> memories, ConversationStats stats) async {
    double trust = 50.0; // Base trust level
    
    // Trust grows with consistent interactions
    if (stats.conversationDuration != null && stats.conversationDuration!.inDays > 0) {
      final dailyInteractions = stats.totalMessages / stats.conversationDuration!.inDays;
      trust += math.min(20.0, dailyInteractions * 2);
    }
    
    // Trust increases with emotional memories
    final emotionalMemories = memories.where((m) => m.isEmotional).length;
    trust += (emotionalMemories * 3);
    
    // Trust decreases if user hasn't interacted recently
    if (stats.lastMessageAt != null) {
      final daysSinceLastMessage = DateTime.now().difference(stats.lastMessageAt!).inDays;
      if (daysSinceLastMessage > 7) {
        trust -= (daysSinceLastMessage - 7) * 2;
      }
    }
    
    return math.max(0.0, math.min(100.0, trust));
  }

  /// Calculate engagement level based on conversation frequency and depth
  Future<double> _calculateEngagementLevel(String companionId, ConversationStats stats) async {
    double engagement = 0.0;
    
    // Recent activity boost
    if (stats.lastMessageAt != null) {
      final daysSinceLastMessage = DateTime.now().difference(stats.lastMessageAt!).inDays;
      engagement += math.max(0.0, 40.0 - (daysSinceLastMessage * 5));
    }
    
    // Conversation frequency
    if (stats.conversationDuration != null && stats.conversationDuration!.inDays > 0) {
      final averageDaily = stats.totalMessages / stats.conversationDuration!.inDays;
      engagement += math.min(30.0, averageDaily * 3);
    }
    
    // Message balance (user vs companion)
    final userRatio = stats.userMessages / math.max(1, stats.totalMessages);
    if (userRatio > 0.3 && userRatio < 0.7) {
      engagement += 20.0; // Good balance
    } else {
      engagement += 10.0; // Imbalanced but still engaged
    }
    
    // Total message count contribution
    engagement += math.min(10.0, stats.totalMessages / 10);
    
    return math.min(100.0, engagement);
  }

  /// Calculate emotional bond strength
  Future<double> _calculateEmotionalBond(String companionId, List<MemoryItem> memories) async {
    double emotional = 0.0;
    
    // Count emotional memories
    final emotionalMemories = memories.where((m) => m.isEmotional).toList();
    emotional += (emotionalMemories.length * 15);
    
    // Weight by importance
    final weightedEmotional = emotionalMemories.fold<double>(0.0, (sum, m) => sum + m.importance * 10);
    emotional += weightedEmotional;
    
    // Recent emotional interactions
    final recentEmotional = emotionalMemories.where((m) => 
      DateTime.now().difference(m.timestamp).inDays < 14
    ).length;
    emotional += (recentEmotional * 5);
    
    // Personal preferences and interests
    final preferenceMemories = memories.where((m) => m.isPreference).length;
    emotional += (preferenceMemories * 3);
    
    return math.min(100.0, emotional);
  }

  /// Calculate consistency score for regular interactions
  Future<double> _calculateConsistencyScore(String companionId, ConversationStats stats) async {
    if (stats.conversationDuration == null || stats.conversationDuration!.inDays < 7) {
      return 0.0;
    }
    
    // Base consistency from conversation duration
    double consistency = math.min(50.0, stats.conversationDuration!.inDays / 2);
    
    // Regular interaction pattern
    final averageDaily = stats.totalMessages / stats.conversationDuration!.inDays;
    if (averageDaily >= 1.0 && averageDaily <= 10.0) {
      consistency += 30.0; // Good regular pattern
    } else if (averageDaily > 0.3) {
      consistency += 15.0; // Some regularity
    }
    
    // Recent activity consistency
    if (stats.lastMessageAt != null) {
      final daysSinceLastMessage = DateTime.now().difference(stats.lastMessageAt!).inDays;
      if (daysSinceLastMessage <= 3) {
        consistency += 20.0;
      } else if (daysSinceLastMessage <= 7) {
        consistency += 10.0;
      }
    }
    
    return math.min(100.0, consistency);
  }

  /// Determine relationship stage based on metrics
  RelationshipStage _determineRelationshipStage(double intimacy, double trust, double engagement, double emotional) {
    final averageScore = (intimacy + trust + engagement + emotional) / 4;
    
    if (averageScore >= 80) {
      return RelationshipStage.soulmate;
    } else if (averageScore >= 65) {
      return RelationshipStage.bestFriend;
    } else if (averageScore >= 50) {
      return RelationshipStage.closeFriend;
    } else if (averageScore >= 35) {
      return RelationshipStage.friend;
    } else if (averageScore >= 20) {
      return RelationshipStage.acquaintance;
    } else {
      return RelationshipStage.stranger;
    }
  }

  /// Calculate overall relationship health
  double _calculateRelationshipHealth(double intimacy, double trust, double engagement, double emotional, double consistency) {
    // Weighted average with emphasis on trust and consistency
    return (intimacy * 0.2) + (trust * 0.3) + (engagement * 0.2) + (emotional * 0.15) + (consistency * 0.15);
  }

  /// Analyze a single interaction for significance
  InteractionAnalysis _analyzeInteraction({
    required String userMessage,
    required String companionResponse,
    required List<Message> conversationHistory,
  }) {
    final userLower = userMessage.toLowerCase();
    bool isSignificant = false;
    double qualityScore = 0.5; // Base quality
    
    // Check for personal information sharing
    final personalIndicators = ['my name', 'i am', 'i work', 'i live', 'my family', 'i feel'];
    bool containsPersonalInfo = personalIndicators.any((indicator) => userLower.contains(indicator));
    
    // Check for emotional content
    final emotionalWords = ['love', 'hate', 'sad', 'happy', 'excited', 'worried', 'grateful'];
    bool containsEmotion = emotionalWords.any((word) => userLower.contains(word));
    
    // Check for questions (curiosity/engagement)
    bool containsQuestion = userMessage.contains('?');
    
    // Check for deep conversation topics
    final deepTopics = ['life', 'philosophy', 'meaning', 'purpose', 'dreams', 'goals'];
    bool containsDeepTopic = deepTopics.any((topic) => userLower.contains(topic));
    
    // Calculate significance
    if (containsPersonalInfo || containsEmotion || containsDeepTopic) {
      isSignificant = true;
      qualityScore += 0.3;
    }
    
    if (containsQuestion) {
      qualityScore += 0.1;
    }
    
    // Message length indicates engagement
    if (userMessage.length > 100) {
      qualityScore += 0.1;
    }
    
    return InteractionAnalysis(
      isSignificant: isSignificant,
      qualityScore: math.min(1.0, qualityScore),
      containsPersonalInfo: containsPersonalInfo,
      containsEmotion: containsEmotion,
      containsQuestion: containsQuestion,
      messageLength: userMessage.length,
    );
  }

  /// Store relationship milestone
  Future<void> _storeMilestone(String companionId, InteractionAnalysis analysis) async {
    if (analysis.containsPersonalInfo) {
      await _memoryManager.storeMemory(
        companionId: companionId,
        content: 'User shared personal information, deepening our connection',
        type: MemoryType.emotional,
        importance: 0.8,
        tags: ['milestone', 'personal_sharing', 'trust'],
      );
    }
    
    if (analysis.containsEmotion) {
      await _memoryManager.storeMemory(
        companionId: companionId,
        content: 'User expressed emotions, showing vulnerability and trust',
        type: MemoryType.emotional,
        importance: 0.7,
        tags: ['milestone', 'emotional_sharing', 'vulnerability'],
      );
    }
  }

  /// Update relationship progression tracking
  Future<void> _updateRelationshipProgression(String companionId, InteractionAnalysis analysis) async {
    // Store interaction quality assessment
    await _memoryManager.storeMemory(
      companionId: companionId,
      content: 'Interaction quality: ${(analysis.qualityScore * 100).toStringAsFixed(0)}%, ${analysis.isSignificant ? "significant" : "routine"} conversation',
      type: MemoryType.system,
      importance: 0.3,
      tags: ['interaction_tracking', 'quality_assessment'],
    );
  }

  /// Get relationship milestones
  Future<List<RelationshipMilestone>> getRelationshipMilestones(String companionId) async {
    final milestoneMemories = await _memoryManager.getCompanionMemories(companionId);
    final relevantMemories = milestoneMemories.where((m) => m.tags.contains('milestone')).toList();
    
    return relevantMemories.map((memory) {
      return RelationshipMilestone(
        id: memory.id,
        companionId: companionId,
        title: _getMilestoneTitle(memory),
        description: memory.content,
        achievedAt: memory.timestamp,
        importance: memory.importance,
        category: _getMilestoneCategory(memory),
      );
    }).toList();
  }

  /// Get milestone title from memory
  String _getMilestoneTitle(MemoryItem memory) {
    if (memory.tags.contains('personal_sharing')) {
      return 'Personal Information Shared';
    } else if (memory.tags.contains('emotional_sharing')) {
      return 'Emotional Connection Deepened';
    } else if (memory.tags.contains('trust')) {
      return 'Trust Level Increased';
    } else {
      return 'Relationship Milestone';
    }
  }

  /// Get milestone category from memory
  MilestoneCategory _getMilestoneCategory(MemoryItem memory) {
    if (memory.tags.contains('personal_sharing')) {
      return MilestoneCategory.personalSharing;
    } else if (memory.tags.contains('emotional_sharing')) {
      return MilestoneCategory.emotionalBonding;
    } else if (memory.tags.contains('trust')) {
      return MilestoneCategory.trustBuilding;
    } else {
      return MilestoneCategory.general;
    }
  }
}

/// Comprehensive relationship metrics
class RelationshipMetrics {
  final double intimacyLevel;
  final double trustLevel;
  final double engagementLevel;
  final double emotionalBond;
  final double consistencyScore;
  final RelationshipStage relationshipStage;
  final double relationshipHealth;
  final int totalInteractions;
  final Duration relationshipDuration;
  final DateTime? lastInteraction;

  const RelationshipMetrics({
    required this.intimacyLevel,
    required this.trustLevel,
    required this.engagementLevel,
    required this.emotionalBond,
    required this.consistencyScore,
    required this.relationshipStage,
    required this.relationshipHealth,
    required this.totalInteractions,
    required this.relationshipDuration,
    this.lastInteraction,
  });

  /// Get overall relationship score
  double get overallScore => (intimacyLevel + trustLevel + engagementLevel + emotionalBond + consistencyScore) / 5;

  /// Check if relationship is healthy
  bool get isHealthy => relationshipHealth >= 60.0;

  /// Check if relationship is active
  bool get isActive {
    if (lastInteraction == null) return false;
    return DateTime.now().difference(lastInteraction!).inDays <= 7;
  }

  /// Get days since last interaction
  int get daysSinceLastInteraction {
    if (lastInteraction == null) return 999;
    return DateTime.now().difference(lastInteraction!).inDays;
  }
}

/// Analysis of a single interaction
class InteractionAnalysis {
  final bool isSignificant;
  final double qualityScore;
  final bool containsPersonalInfo;
  final bool containsEmotion;
  final bool containsQuestion;
  final int messageLength;

  const InteractionAnalysis({
    required this.isSignificant,
    required this.qualityScore,
    required this.containsPersonalInfo,
    required this.containsEmotion,
    required this.containsQuestion,
    required this.messageLength,
  });
}

/// Relationship milestone
class RelationshipMilestone {
  final String id;
  final String companionId;
  final String title;
  final String description;
  final DateTime achievedAt;
  final double importance;
  final MilestoneCategory category;

  const RelationshipMilestone({
    required this.id,
    required this.companionId,
    required this.title,
    required this.description,
    required this.achievedAt,
    required this.importance,
    required this.category,
  });
}

/// Relationship stages
enum RelationshipStage {
  stranger,
  acquaintance,
  friend,
  closeFriend,
  bestFriend,
  soulmate,
}

/// Milestone categories
enum MilestoneCategory {
  personalSharing,
  emotionalBonding,
  trustBuilding,
  consistencyBuilding,
  general,
}