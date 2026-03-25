import 'dart:math' as math;

import 'memory_manager.dart';
import 'models/memory_item.dart';
import '../../shared/models/message.dart';

/// Advanced context management for conversations
class ContextManager {
  final MemoryManager _memoryManager;

  // Context configuration
  static const int maxContextItems = 10;
  static const double contextRelevanceThreshold = 0.3;
  static const double recentContextBoost = 0.5;
  static const double personalContextBoost = 0.8;

  ContextManager({
    required MemoryManager memoryManager,
  }) : _memoryManager = memoryManager;

  /// Get contextual information for a conversation
  Future<ConversationContext> buildConversationContext({
    required String companionId,
    required List<Message> recentMessages,
    required String currentQuery,
    int maxMemories = maxContextItems,
  }) async {
    // Get relevant memories using enhanced scoring
    final relevantMemories = await _getContextualMemories(
      companionId: companionId,
      recentMessages: recentMessages,
      currentQuery: currentQuery,
      maxMemories: maxMemories,
    );

    // Extract conversation patterns
    final patterns = _analyzeConversationPatterns(recentMessages);

    // Determine conversation mood and tone
    final mood = _analyzeMood(recentMessages);

    // Get user preferences from memories
    final preferences = await _extractUserPreferences(companionId, relevantMemories);

    // Build relationship context
    final relationship = await _buildRelationshipContext(companionId, relevantMemories);

    return ConversationContext(
      relevantMemories: relevantMemories,
      conversationPatterns: patterns,
      currentMood: mood,
      userPreferences: preferences,
      relationshipContext: relationship,
      contextScore: _calculateOverallContextScore(relevantMemories),
    );
  }

  /// Get memories that are most relevant to current conversation
  Future<List<MemoryItem>> _getContextualMemories({
    required String companionId,
    required List<Message> recentMessages,
    required String currentQuery,
    required int maxMemories,
  }) async {
    final allMemories = await _memoryManager.getCompanionMemories(companionId);
    
    // Score memories based on multiple factors
    final scoredMemories = allMemories.map((memory) {
      final score = _calculateContextualScore(
        memory: memory,
        recentMessages: recentMessages,
        currentQuery: currentQuery,
      );
      return _ScoredMemory(memory, score);
    }).toList();

    // Sort by contextual score and return top results
    scoredMemories.sort((a, b) => b.score.compareTo(a.score));
    
    // Filter by minimum relevance threshold
    final relevantMemories = scoredMemories
        .where((scored) => scored.score >= contextRelevanceThreshold)
        .take(maxMemories)
        .map((scored) => scored.memory)
        .toList();

    return relevantMemories;
  }

  /// Calculate contextual relevance score for a memory
  double _calculateContextualScore({
    required MemoryItem memory,
    required List<Message> recentMessages,
    required String currentQuery,
  }) {
    double score = 0.0;

    // Base relevance to current query
    score += _calculateQueryRelevance(memory, currentQuery) * 0.4;

    // Relevance to recent conversation
    score += _calculateConversationRelevance(memory, recentMessages) * 0.3;

    // Memory type importance
    score += _getMemoryTypeWeight(memory.type) * 0.1;

    // Recency boost
    score += _calculateRecencyScore(memory) * 0.1;

    // Personal information gets higher weight
    if (memory.isPersonalInfo) {
      score += personalContextBoost * 0.1;
    }

    return math.min(1.0, score * memory.importance);
  }

  /// Calculate relevance to current query
  double _calculateQueryRelevance(MemoryItem memory, String query) {
    final queryLower = query.toLowerCase();
    final contentLower = memory.content.toLowerCase();
    
    // Direct keyword matching
    double keywordScore = 0.0;
    final queryWords = queryLower.split(' ').where((w) => w.length > 2).toList();
    
    for (final word in queryWords) {
      if (contentLower.contains(word)) {
        keywordScore += 1.0 / queryWords.length;
      }
    }

    // Tag matching
    double tagScore = 0.0;
    for (final tag in memory.tags) {
      if (queryLower.contains(tag.toLowerCase())) {
        tagScore += 0.3;
      }
    }

    return math.min(1.0, keywordScore + tagScore);
  }

  /// Calculate relevance to recent conversation
  double _calculateConversationRelevance(MemoryItem memory, List<Message> recentMessages) {
    if (recentMessages.isEmpty) return 0.0;

    double relevanceScore = 0.0;
    final recentContent = recentMessages
        .take(5) // Look at last 5 messages
        .map((m) => m.content.toLowerCase())
        .join(' ');

    // Check for thematic similarity
    final memoryWords = memory.content.toLowerCase().split(' ');
    final recentWords = recentContent.split(' ');
    
    int commonWords = 0;
    for (final word in memoryWords) {
      if (word.length > 3 && recentWords.contains(word)) {
        commonWords++;
      }
    }

    if (memoryWords.isNotEmpty) {
      relevanceScore = commonWords / memoryWords.length;
    }

    return math.min(1.0, relevanceScore);
  }

  /// Get weight based on memory type
  double _getMemoryTypeWeight(MemoryType type) {
    switch (type) {
      case MemoryType.personal:
        return 0.9;
      case MemoryType.preference:
        return 0.8;
      case MemoryType.emotional:
        return 0.7;
      case MemoryType.factual:
        return 0.6;
      case MemoryType.conversation:
        return 0.5;
      case MemoryType.system:
        return 0.2;
    }
  }

  /// Calculate recency score
  double _calculateRecencyScore(MemoryItem memory) {
    final daysSince = DateTime.now().difference(memory.timestamp).inDays;
    return math.exp(-daysSince / 14.0); // 14-day half-life
  }

  /// Analyze conversation patterns
  ConversationPatterns _analyzeConversationPatterns(List<Message> messages) {
    if (messages.isEmpty) {
      return const ConversationPatterns(
        averageMessageLength: 0,
        userMessageFrequency: 0,
        topicsDiscussed: [],
        conversationStyle: ConversationStyle.casual,
      );
    }

    // Calculate average message length
    final totalLength = messages.fold<int>(0, (sum, msg) => sum + msg.content.length);
    final avgLength = totalLength / messages.length;

    // Analyze user message frequency
    final userMessages = messages.where((m) => m.role == MessageRole.user).length;
    final frequency = userMessages / messages.length;

    // Extract topics (simplified - could use NLP)
    final topics = _extractTopics(messages);

    // Determine conversation style
    final style = _determineConversationStyle(messages);

    return ConversationPatterns(
      averageMessageLength: avgLength,
      userMessageFrequency: frequency,
      topicsDiscussed: topics,
      conversationStyle: style,
    );
  }

  /// Extract topics from conversation
  List<String> _extractTopics(List<Message> messages) {
    // Simple keyword extraction - in production, use NLP
    final allText = messages.map((m) => m.content.toLowerCase()).join(' ');
    final words = allText.split(' ');
    
    // Common topic keywords
    final topicKeywords = {
      'work': ['work', 'job', 'career', 'office', 'colleague'],
      'family': ['family', 'mother', 'father', 'sister', 'brother', 'parent'],
      'hobby': ['hobby', 'interest', 'enjoy', 'like', 'love', 'passion'],
      'food': ['food', 'eat', 'cook', 'restaurant', 'meal', 'lunch', 'dinner'],
      'travel': ['travel', 'trip', 'vacation', 'visit', 'country', 'city'],
      'health': ['health', 'exercise', 'fitness', 'doctor', 'medicine'],
      'technology': ['technology', 'computer', 'phone', 'internet', 'software'],
      'entertainment': ['movie', 'music', 'game', 'book', 'show', 'watch'],
    };

    final detectedTopics = <String>[];
    for (final topic in topicKeywords.keys) {
      final keywords = topicKeywords[topic]!;
      if (keywords.any((keyword) => words.contains(keyword))) {
        detectedTopics.add(topic);
      }
    }

    return detectedTopics;
  }

  /// Determine conversation style
  ConversationStyle _determineConversationStyle(List<Message> messages) {
    final allText = messages.map((m) => m.content.toLowerCase()).join(' ');
    
    // Check for formal language patterns
    final formalIndicators = ['please', 'thank you', 'would you', 'could you'];
    final casualIndicators = ['hey', 'yeah', 'cool', 'awesome', 'lol'];
    final deepIndicators = ['feel', 'think', 'believe', 'philosophy', 'meaning'];

    int formalCount = 0;
    int casualCount = 0;
    int deepCount = 0;

    for (final indicator in formalIndicators) {
      if (allText.contains(indicator)) formalCount++;
    }
    for (final indicator in casualIndicators) {
      if (allText.contains(indicator)) casualCount++;
    }
    for (final indicator in deepIndicators) {
      if (allText.contains(indicator)) deepCount++;
    }

    if (deepCount > formalCount && deepCount > casualCount) {
      return ConversationStyle.philosophical;
    } else if (formalCount > casualCount) {
      return ConversationStyle.formal;
    } else {
      return ConversationStyle.casual;
    }
  }

  /// Analyze current mood from recent messages
  ConversationMood _analyzeMood(List<Message> messages) {
    if (messages.isEmpty) return ConversationMood.neutral;

    final recentMessages = messages.take(3).map((m) => m.content.toLowerCase()).join(' ');
    
    // Sentiment keywords (simplified sentiment analysis)
    final positiveWords = ['happy', 'great', 'awesome', 'love', 'excited', 'good', 'amazing'];
    final negativeWords = ['sad', 'angry', 'hate', 'bad', 'terrible', 'frustrated', 'upset'];
    final curiousWords = ['what', 'how', 'why', 'tell me', 'explain', 'learn', 'understand'];

    int positiveCount = 0;
    int negativeCount = 0;
    int curiousCount = 0;

    for (final word in positiveWords) {
      if (recentMessages.contains(word)) positiveCount++;
    }
    for (final word in negativeWords) {
      if (recentMessages.contains(word)) negativeCount++;
    }
    for (final word in curiousWords) {
      if (recentMessages.contains(word)) curiousCount++;
    }

    if (curiousCount > 0) return ConversationMood.curious;
    if (positiveCount > negativeCount) return ConversationMood.positive;
    if (negativeCount > positiveCount) return ConversationMood.negative;
    return ConversationMood.neutral;
  }

  /// Extract user preferences from memories
  Future<UserPreferences> _extractUserPreferences(String companionId, List<MemoryItem> memories) async {
    final preferenceMemories = memories.where((m) => m.isPreference).toList();
    
    final likes = <String>[];
    final dislikes = <String>[];
    final interests = <String>[];

    for (final memory in preferenceMemories) {
      if (memory.tags.contains('likes')) {
        likes.add(memory.content);
      } else if (memory.tags.contains('dislikes')) {
        dislikes.add(memory.content);
      }
      
      if (memory.tags.contains('interest')) {
        interests.add(memory.content);
      }
    }

    return UserPreferences(
      likes: likes,
      dislikes: dislikes,
      interests: interests,
    );
  }

  /// Build relationship context
  Future<RelationshipContext> _buildRelationshipContext(String companionId, List<MemoryItem> memories) async {
    final totalMemories = memories.length;
    final personalMemories = memories.where((m) => m.isPersonalInfo).length;
    final conversationDays = memories.isNotEmpty
        ? DateTime.now().difference(memories.first.timestamp).inDays
        : 0;

    // Calculate intimacy level based on personal information shared
    double intimacyLevel = 0.0;
    if (totalMemories > 0) {
      intimacyLevel = (personalMemories / totalMemories) * 100;
    }

    // Determine relationship stage
    RelationshipStage stage;
    if (conversationDays < 1) {
      stage = RelationshipStage.introduction;
    } else if (conversationDays < 7) {
      stage = RelationshipStage.acquaintance;
    } else if (conversationDays < 30 && intimacyLevel > 30) {
      stage = RelationshipStage.friend;
    } else if (intimacyLevel > 60) {
      stage = RelationshipStage.close;
    } else {
      stage = RelationshipStage.acquaintance;
    }

    return RelationshipContext(
      totalInteractions: totalMemories,
      personalInfoShared: personalMemories,
      relationshipDuration: Duration(days: conversationDays),
      intimacyLevel: intimacyLevel,
      relationshipStage: stage,
    );
  }

  /// Calculate overall context quality score
  double _calculateOverallContextScore(List<MemoryItem> memories) {
    if (memories.isEmpty) return 0.0;
    
    final avgImportance = memories.fold<double>(0.0, (sum, m) => sum + m.importance) / memories.length;
    final typeVariety = memories.map((m) => m.type).toSet().length / MemoryType.values.length;
    final recencyScore = memories.fold<double>(0.0, (sum, m) => sum + _calculateRecencyScore(m)) / memories.length;
    
    return (avgImportance * 0.5) + (typeVariety * 0.3) + (recencyScore * 0.2);
  }
}

/// Helper class for scored memories
class _ScoredMemory {
  final MemoryItem memory;
  final double score;

  _ScoredMemory(this.memory, this.score);
}

/// Comprehensive conversation context
class ConversationContext {
  final List<MemoryItem> relevantMemories;
  final ConversationPatterns conversationPatterns;
  final ConversationMood currentMood;
  final UserPreferences userPreferences;
  final RelationshipContext relationshipContext;
  final double contextScore;

  const ConversationContext({
    required this.relevantMemories,
    required this.conversationPatterns,
    required this.currentMood,
    required this.userPreferences,
    required this.relationshipContext,
    required this.contextScore,
  });

  /// Generate context summary for AI prompts
  String generateContextSummary() {
    final buffer = StringBuffer();
    
    // Relationship context
    buffer.writeln('RELATIONSHIP CONTEXT:');
    buffer.writeln('- Stage: ${relationshipContext.relationshipStage.name}');
    buffer.writeln('- Duration: ${relationshipContext.relationshipDuration.inDays} days');
    buffer.writeln('- Intimacy Level: ${relationshipContext.intimacyLevel.toStringAsFixed(1)}%');
    
    // User preferences
    if (userPreferences.likes.isNotEmpty) {
      buffer.writeln('\nUSER LIKES: ${userPreferences.likes.join(', ')}');
    }
    if (userPreferences.dislikes.isNotEmpty) {
      buffer.writeln('USER DISLIKES: ${userPreferences.dislikes.join(', ')}');
    }
    
    // Conversation mood
    buffer.writeln('\nCURRENT MOOD: ${currentMood.name}');
    
    // Relevant memories
    if (relevantMemories.isNotEmpty) {
      buffer.writeln('\nRELEVANT MEMORIES:');
      for (final memory in relevantMemories.take(5)) {
        buffer.writeln('- ${memory.content}');
      }
    }
    
    return buffer.toString();
  }
}

/// Analysis of conversation patterns
class ConversationPatterns {
  final double averageMessageLength;
  final double userMessageFrequency;
  final List<String> topicsDiscussed;
  final ConversationStyle conversationStyle;

  const ConversationPatterns({
    required this.averageMessageLength,
    required this.userMessageFrequency,
    required this.topicsDiscussed,
    required this.conversationStyle,
  });
}

/// User preferences extracted from memories
class UserPreferences {
  final List<String> likes;
  final List<String> dislikes;
  final List<String> interests;

  const UserPreferences({
    required this.likes,
    required this.dislikes,
    required this.interests,
  });
}

/// Relationship context information
class RelationshipContext {
  final int totalInteractions;
  final int personalInfoShared;
  final Duration relationshipDuration;
  final double intimacyLevel;
  final RelationshipStage relationshipStage;

  const RelationshipContext({
    required this.totalInteractions,
    required this.personalInfoShared,
    required this.relationshipDuration,
    required this.intimacyLevel,
    required this.relationshipStage,
  });
}

/// Possible conversation moods
enum ConversationMood {
  positive,
  negative,
  neutral,
  curious,
  excited,
  confused,
}

/// Conversation styles
enum ConversationStyle {
  casual,
  formal,
  philosophical,
  playful,
  supportive,
}

/// Relationship stages
enum RelationshipStage {
  introduction,
  acquaintance,
  friend,
  close,
}