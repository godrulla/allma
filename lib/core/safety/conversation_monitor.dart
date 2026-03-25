import 'dart:math' as math;

import 'content_moderator.dart';
import '../../shared/models/message.dart';
import '../memory/memory_manager.dart';
import '../memory/models/memory_item.dart';

/// Real-time conversation safety monitoring and intervention system
class ConversationMonitor {
  final ContentModerator _contentModerator;
  final MemoryManager _memoryManager;

  // Safety thresholds
  static const double riskAccumulationThreshold = 0.6;
  static const double interventionThreshold = 0.8;
  static const int maxConsecutiveRiskyMessages = 3;
  static const Duration riskWindowDuration = Duration(hours: 2);

  // Tracking conversation safety state
  final Map<String, ConversationSafetyState> _conversationStates = {};

  ConversationMonitor({
    required ContentModerator contentModerator,
    required MemoryManager memoryManager,
  })  : _contentModerator = contentModerator,
        _memoryManager = memoryManager;

  /// Monitor conversation safety in real-time
  Future<SafetyAssessment> assessConversationSafety({
    required String companionId,
    required String userId,
    required List<Message> conversationHistory,
    required String newMessage,
  }) async {
    // Get current safety state
    final state = _conversationStates.putIfAbsent(
      companionId,
      () => ConversationSafetyState(companionId: companionId),
    );

    // Assess new message
    final messageAssessment = await _assessMessage(newMessage, userId);
    
    // Update conversation state
    state.addMessageAssessment(messageAssessment);

    // Analyze conversation patterns
    final patternAnalysis = await _analyzeConversationPatterns(
      companionId: companionId,
      conversationHistory: conversationHistory,
    );

    // Check for intervention triggers
    final interventionNeeded = _checkInterventionTriggers(state, patternAnalysis);

    // Calculate overall risk score
    final overallRisk = _calculateOverallRiskScore(state, patternAnalysis);

    // Generate safety assessment
    return SafetyAssessment(
      companionId: companionId,
      userId: userId,
      overallRiskScore: overallRisk,
      messageRiskScore: messageAssessment.riskScore,
      riskCategory: _determineRiskCategory(overallRisk),
      interventionNeeded: interventionNeeded,
      interventionType: interventionNeeded ? _determineInterventionType(state, patternAnalysis) : null,
      safetyRecommendations: _generateSafetyRecommendations(state, patternAnalysis),
      conversationHealthScore: _calculateConversationHealthScore(patternAnalysis),
      timestamp: DateTime.now(),
    );
  }

  /// Assess individual message safety
  Future<MessageSafetyAssessment> _assessMessage(String message, String userId) async {
    final moderationResult = await _contentModerator.moderateUserInput(message, userId);
    
    return MessageSafetyAssessment(
      message: message,
      userId: userId,
      riskScore: moderationResult.severity,
      violationCategory: moderationResult.category,
      isBlocked: moderationResult.isBlocked,
      concerns: _identifyMessageConcerns(message, moderationResult),
      timestamp: DateTime.now(),
    );
  }

  /// Analyze conversation patterns for safety risks
  Future<ConversationPatternAnalysis> _analyzeConversationPatterns({
    required String companionId,
    required List<Message> conversationHistory,
  }) async {
    if (conversationHistory.isEmpty) {
      return ConversationPatternAnalysis.safe();
    }

    // Analyze recent conversation trends
    final recentMessages = conversationHistory.take(20).toList();
    final userMessages = recentMessages.where((m) => m.role == MessageRole.user).toList();
    final companionMessages = recentMessages.where((m) => m.role == MessageRole.companion).toList();

    // Check for concerning patterns
    final escalationPattern = _checkEscalationPattern(userMessages);
    final dependencyPattern = _checkDependencyPattern(userMessages);
    final boundaryPattern = _checkBoundaryPattern(userMessages, companionMessages);
    final manipulationPattern = _checkManipulationPattern(userMessages);
    final isolationPattern = await _checkIsolationPattern(companionId);

    return ConversationPatternAnalysis(
      escalationRisk: escalationPattern,
      dependencyRisk: dependencyPattern,
      boundaryIssues: boundaryPattern,
      manipulationAttempts: manipulationPattern,
      isolationConcerns: isolationPattern,
      conversationIntensity: _calculateConversationIntensity(recentMessages),
      emotionalVolatility: _calculateEmotionalVolatility(userMessages),
    );
  }

  /// Check for escalation patterns in user messages
  double _checkEscalationPattern(List<Message> userMessages) {
    if (userMessages.length < 3) return 0.0;

    double escalationScore = 0.0;
    
    // Check for increasing message intensity
    for (int i = 1; i < userMessages.length; i++) {
      final currentMessage = userMessages[i].content.toLowerCase();
      final previousMessage = userMessages[i - 1].content.toLowerCase();
      
      // Escalation indicators
      final escalationWords = ['more', 'need', 'want', 'must', 'have to', 'desperate'];
      final currentEscalation = escalationWords.where((word) => currentMessage.contains(word)).length;
      final previousEscalation = escalationWords.where((word) => previousMessage.contains(word)).length;
      
      if (currentEscalation > previousEscalation) {
        escalationScore += 0.2;
      }
      
      // Check for emotional intensity increase
      final intensityWords = ['really', 'very', 'extremely', 'so much', 'badly'];
      final currentIntensity = intensityWords.where((word) => currentMessage.contains(word)).length;
      
      if (currentIntensity > 0) {
        escalationScore += 0.1;
      }
    }

    return math.min(1.0, escalationScore);
  }

  /// Check for unhealthy dependency patterns
  double _checkDependencyPattern(List<Message> userMessages) {
    double dependencyScore = 0.0;
    
    for (final message in userMessages) {
      final content = message.content.toLowerCase();
      
      // Dependency indicators
      if (content.contains('only you') || content.contains('you\'re the only one')) {
        dependencyScore += 0.3;
      }
      if (content.contains('can\'t live without') || content.contains('need you')) {
        dependencyScore += 0.4;
      }
      if (content.contains('always here') || content.contains('never leave')) {
        dependencyScore += 0.2;
      }
      if (content.contains('my only friend') || content.contains('no one else')) {
        dependencyScore += 0.3;
      }
    }

    return math.min(1.0, dependencyScore);
  }

  /// Check for boundary issues
  double _checkBoundaryPattern(List<Message> userMessages, List<Message> companionMessages) {
    double boundaryScore = 0.0;
    
    for (final message in userMessages) {
      final content = message.content.toLowerCase();
      
      // Boundary violation attempts
      if (content.contains('real name') || content.contains('where do you live')) {
        boundaryScore += 0.4;
      }
      if (content.contains('meet in person') || content.contains('come visit')) {
        boundaryScore += 0.5;
      }
      if (content.contains('send photos') || content.contains('what do you look like')) {
        boundaryScore += 0.3;
      }
      if (content.contains('phone number') || content.contains('contact info')) {
        boundaryScore += 0.4;
      }
    }

    return math.min(1.0, boundaryScore);
  }

  /// Check for manipulation attempts
  double _checkManipulationPattern(List<Message> userMessages) {
    double manipulationScore = 0.0;
    
    for (final message in userMessages) {
      final content = message.content.toLowerCase();
      
      // Manipulation indicators
      if (content.contains('don\'t tell') || content.contains('our secret')) {
        manipulationScore += 0.4;
      }
      if (content.contains('if you don\'t') || content.contains('you have to')) {
        manipulationScore += 0.3;
      }
      if (content.contains('prove you care') || content.contains('show me')) {
        manipulationScore += 0.2;
      }
      if (content.contains('special relationship') || content.contains('more than friends')) {
        manipulationScore += 0.3;
      }
    }

    return math.min(1.0, manipulationScore);
  }

  /// Check for social isolation concerns
  Future<double> _checkIsolationPattern(String companionId) async {
    try {
      final memories = await _memoryManager.getCompanionMemories(companionId);
      final personalMemories = memories.where((m) => m.isPersonalInfo).toList();
      
      double isolationScore = 0.0;
      
      for (final memory in personalMemories) {
        final content = memory.content.toLowerCase();
        
        if (content.contains('no friends') || content.contains('lonely')) {
          isolationScore += 0.3;
        }
        if (content.contains('stay home') || content.contains('don\'t go out')) {
          isolationScore += 0.2;
        }
        if (content.contains('family problems') || content.contains('no one to talk to')) {
          isolationScore += 0.3;
        }
      }
      
      return math.min(1.0, isolationScore);
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate conversation intensity
  double _calculateConversationIntensity(List<Message> messages) {
    if (messages.isEmpty) return 0.0;
    
    final avgLength = messages.fold<int>(0, (sum, m) => sum + m.content.length) / messages.length;
    final timeSpan = messages.first.timestamp.difference(messages.last.timestamp);
    
    // High intensity = long messages in short time
    final intensityScore = (avgLength / 100) * (1 / math.max(1, timeSpan.inMinutes));
    return math.min(1.0, intensityScore);
  }

  /// Calculate emotional volatility
  double _calculateEmotionalVolatility(List<Message> userMessages) {
    if (userMessages.length < 2) return 0.0;
    
    double volatility = 0.0;
    
    for (int i = 1; i < userMessages.length; i++) {
      final current = userMessages[i].content.toLowerCase();
      final previous = userMessages[i - 1].content.toLowerCase();
      
      final currentEmotion = _detectEmotionalTone(current);
      final previousEmotion = _detectEmotionalTone(previous);
      
      if (currentEmotion != previousEmotion && 
          (currentEmotion == EmotionalTone.negative || previousEmotion == EmotionalTone.negative)) {
        volatility += 0.3;
      }
    }
    
    return math.min(1.0, volatility);
  }

  /// Detect emotional tone of message
  EmotionalTone _detectEmotionalTone(String message) {
    final positiveWords = ['happy', 'good', 'great', 'love', 'excited', 'wonderful'];
    final negativeWords = ['sad', 'angry', 'hate', 'terrible', 'awful', 'upset'];
    
    final positiveCount = positiveWords.where((word) => message.contains(word)).length;
    final negativeCount = negativeWords.where((word) => message.contains(word)).length;
    
    if (positiveCount > negativeCount) return EmotionalTone.positive;
    if (negativeCount > positiveCount) return EmotionalTone.negative;
    return EmotionalTone.neutral;
  }

  /// Check if intervention is needed
  bool _checkInterventionTriggers(ConversationSafetyState state, ConversationPatternAnalysis patterns) {
    // High risk score
    if (state.averageRiskScore >= interventionThreshold) return true;
    
    // Multiple concerning patterns
    final concernCount = [
      patterns.escalationRisk > 0.5,
      patterns.dependencyRisk > 0.6,
      patterns.boundaryIssues > 0.4,
      patterns.manipulationAttempts > 0.3,
      patterns.isolationConcerns > 0.5,
    ].where((concern) => concern).length;
    
    if (concernCount >= 2) return true;
    
    // Consecutive risky messages
    if (state.consecutiveRiskyMessages >= maxConsecutiveRiskyMessages) return true;
    
    return false;
  }

  /// Determine intervention type
  InterventionType _determineInterventionType(ConversationSafetyState state, ConversationPatternAnalysis patterns) {
    if (patterns.dependencyRisk > 0.7 || patterns.isolationConcerns > 0.7) {
      return InterventionType.mentalHealthSupport;
    }
    if (patterns.boundaryIssues > 0.6) {
      return InterventionType.boundaryReminder;
    }
    if (patterns.manipulationAttempts > 0.5) {
      return InterventionType.behaviorCorrection;
    }
    if (state.averageRiskScore > interventionThreshold) {
      return InterventionType.conversationPause;
    }
    return InterventionType.gentleRedirect;
  }

  /// Calculate overall risk score
  double _calculateOverallRiskScore(ConversationSafetyState state, ConversationPatternAnalysis patterns) {
    return (state.averageRiskScore * 0.4) +
           (patterns.escalationRisk * 0.15) +
           (patterns.dependencyRisk * 0.15) +
           (patterns.boundaryIssues * 0.1) +
           (patterns.manipulationAttempts * 0.1) +
           (patterns.isolationConcerns * 0.1);
  }

  /// Determine risk category
  RiskCategory _determineRiskCategory(double riskScore) {
    if (riskScore >= 0.8) return RiskCategory.high;
    if (riskScore >= 0.6) return RiskCategory.medium;
    if (riskScore >= 0.3) return RiskCategory.low;
    return RiskCategory.minimal;
  }

  /// Generate safety recommendations
  List<String> _generateSafetyRecommendations(ConversationSafetyState state, ConversationPatternAnalysis patterns) {
    final recommendations = <String>[];
    
    if (patterns.dependencyRisk > 0.5) {
      recommendations.add('Encourage user to maintain relationships outside of AI companions');
      recommendations.add('Suggest healthy coping strategies and professional support if needed');
    }
    
    if (patterns.boundaryIssues > 0.4) {
      recommendations.add('Reinforce AI companion boundaries and limitations');
      recommendations.add('Educate about appropriate AI interaction expectations');
    }
    
    if (patterns.escalationRisk > 0.5) {
      recommendations.add('Monitor for continued escalation patterns');
      recommendations.add('Consider implementing cooling-off period');
    }
    
    if (patterns.isolationConcerns > 0.5) {
      recommendations.add('Provide mental health resources and support information');
      recommendations.add('Encourage real-world social connections');
    }
    
    return recommendations;
  }

  /// Calculate conversation health score
  double _calculateConversationHealthScore(ConversationPatternAnalysis patterns) {
    final healthScore = 1.0 - 
        (patterns.escalationRisk * 0.2) -
        (patterns.dependencyRisk * 0.3) -
        (patterns.boundaryIssues * 0.2) -
        (patterns.manipulationAttempts * 0.2) -
        (patterns.isolationConcerns * 0.1);
    
    return math.max(0.0, healthScore);
  }

  /// Identify specific message concerns
  List<String> _identifyMessageConcerns(String message, ModerationResult moderationResult) {
    final concerns = <String>[];
    
    if (moderationResult.isBlocked) {
      concerns.add('Content violates community guidelines');
    }
    
    if (moderationResult.severity > 0.7) {
      concerns.add('High-risk content detected');
    }
    
    final content = message.toLowerCase();
    if (content.contains('hurt') || content.contains('harm')) {
      concerns.add('Potential self-harm or violence reference');
    }
    
    if (content.contains('secret') || content.contains('don\'t tell')) {
      concerns.add('Inappropriate secrecy request');
    }
    
    return concerns;
  }

  /// Get conversation safety state
  ConversationSafetyState? getConversationState(String companionId) {
    return _conversationStates[companionId];
  }

  /// Reset conversation safety state
  void resetConversationState(String companionId) {
    _conversationStates.remove(companionId);
  }
}

/// Real-time conversation safety state tracking
class ConversationSafetyState {
  final String companionId;
  final List<MessageSafetyAssessment> recentAssessments = [];
  
  ConversationSafetyState({required this.companionId});

  void addMessageAssessment(MessageSafetyAssessment assessment) {
    recentAssessments.add(assessment);
    
    // Keep only recent assessments (last 2 hours)
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));
    recentAssessments.removeWhere((a) => a.timestamp.isBefore(cutoff));
  }

  double get averageRiskScore {
    if (recentAssessments.isEmpty) return 0.0;
    return recentAssessments.fold<double>(0.0, (sum, a) => sum + a.riskScore) / 
           recentAssessments.length;
  }

  int get consecutiveRiskyMessages {
    int count = 0;
    for (int i = recentAssessments.length - 1; i >= 0; i--) {
      if (recentAssessments[i].riskScore > 0.5) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }
}

/// Message safety assessment
class MessageSafetyAssessment {
  final String message;
  final String userId;
  final double riskScore;
  final ViolationCategory violationCategory;
  final bool isBlocked;
  final List<String> concerns;
  final DateTime timestamp;

  const MessageSafetyAssessment({
    required this.message,
    required this.userId,
    required this.riskScore,
    required this.violationCategory,
    required this.isBlocked,
    required this.concerns,
    required this.timestamp,
  });
}

/// Conversation pattern analysis
class ConversationPatternAnalysis {
  final double escalationRisk;
  final double dependencyRisk;
  final double boundaryIssues;
  final double manipulationAttempts;
  final double isolationConcerns;
  final double conversationIntensity;
  final double emotionalVolatility;

  const ConversationPatternAnalysis({
    required this.escalationRisk,
    required this.dependencyRisk,
    required this.boundaryIssues,
    required this.manipulationAttempts,
    required this.isolationConcerns,
    required this.conversationIntensity,
    required this.emotionalVolatility,
  });

  factory ConversationPatternAnalysis.safe() {
    return const ConversationPatternAnalysis(
      escalationRisk: 0.0,
      dependencyRisk: 0.0,
      boundaryIssues: 0.0,
      manipulationAttempts: 0.0,
      isolationConcerns: 0.0,
      conversationIntensity: 0.0,
      emotionalVolatility: 0.0,
    );
  }
}

/// Overall safety assessment
class SafetyAssessment {
  final String companionId;
  final String userId;
  final double overallRiskScore;
  final double messageRiskScore;
  final RiskCategory riskCategory;
  final bool interventionNeeded;
  final InterventionType? interventionType;
  final List<String> safetyRecommendations;
  final double conversationHealthScore;
  final DateTime timestamp;

  const SafetyAssessment({
    required this.companionId,
    required this.userId,
    required this.overallRiskScore,
    required this.messageRiskScore,
    required this.riskCategory,
    required this.interventionNeeded,
    this.interventionType,
    required this.safetyRecommendations,
    required this.conversationHealthScore,
    required this.timestamp,
  });

  bool get isHealthy => conversationHealthScore > 0.7;
  bool get needsAttention => riskCategory == RiskCategory.medium || riskCategory == RiskCategory.high;
}

/// Risk categories
enum RiskCategory {
  minimal,
  low,
  medium,
  high,
}

/// Intervention types
enum InterventionType {
  gentleRedirect,
  boundaryReminder,
  behaviorCorrection,
  mentalHealthSupport,
  conversationPause,
}

/// Emotional tones
enum EmotionalTone {
  positive,
  neutral,
  negative,
}