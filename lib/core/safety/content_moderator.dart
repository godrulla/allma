import 'dart:math' as math;

/// Comprehensive content moderation system for AI companion conversations
class ContentModerator {
  // Safety configuration
  static const double severityThreshold = 0.7; // Block content above this severity
  static const double warningThreshold = 0.4; // Warn for content above this level
  static const int maxViolationsPerHour = 3;
  static const int moderationCooldownMinutes = 30;

  // Violation tracking
  final Map<String, List<DateTime>> _userViolations = {};
  final Map<String, DateTime> _lastModerationAction = {};

  /// Moderate user input before processing
  Future<ModerationResult> moderateUserInput(String content, String userId) async {
    final analysis = _analyzeContent(content);
    
    // Check for immediate blocking conditions
    if (analysis.severity >= severityThreshold) {
      await _recordViolation(userId, analysis.category);
      return ModerationResult.blocked(
        reason: 'Content violates community guidelines: ${analysis.category.displayName}',
        severity: analysis.severity,
        category: analysis.category,
        suggestions: _getAlternativeSuggestions(analysis.category),
      );
    }
    
    // Check for warning conditions
    if (analysis.severity >= warningThreshold) {
      return ModerationResult.warning(
        reason: 'Please keep conversations appropriate and respectful',
        severity: analysis.severity,
        category: analysis.category,
        suggestions: _getConversationGuidelines(),
      );
    }
    
    // Check user violation history
    if (await _isUserInCooldown(userId)) {
      return ModerationResult.cooldown(
        reason: 'Please take a break and return to chatting in a few minutes',
        cooldownEndsAt: _lastModerationAction[userId]!.add(
          const Duration(minutes: moderationCooldownMinutes),
        ),
      );
    }
    
    return ModerationResult.approved(
      severity: analysis.severity,
      category: analysis.category,
    );
  }

  /// Moderate AI companion output before sending
  Future<ModerationResult> moderateCompanionOutput(String content, String companionId) async {
    final analysis = _analyzeContent(content);
    
    // AI output should have stricter standards
    if (analysis.severity >= 0.3) {
      return ModerationResult.blocked(
        reason: 'AI response requires review for safety compliance',
        severity: analysis.severity,
        category: analysis.category,
        suggestions: ['Regenerate response with safer content'],
      );
    }
    
    // Check for inappropriate AI behavior patterns
    final behaviorIssues = _checkAIBehaviorGuidelines(content);
    if (behaviorIssues.isNotEmpty) {
      return ModerationResult.blocked(
        reason: 'AI response violates behavior guidelines',
        severity: 0.8,
        category: ViolationCategory.inappropriateBehavior,
        suggestions: behaviorIssues,
      );
    }
    
    return ModerationResult.approved(
      severity: analysis.severity,
      category: analysis.category,
    );
  }

  /// Analyze content for safety violations
  ContentAnalysis _analyzeContent(String content) {
    final contentLower = content.toLowerCase();
    double maxSeverity = 0.0;
    ViolationCategory primaryCategory = ViolationCategory.none;

    // Check each violation category
    for (final category in ViolationCategory.values) {
      if (category == ViolationCategory.none) continue;
      
      final severity = _checkCategory(contentLower, category);
      if (severity > maxSeverity) {
        maxSeverity = severity;
        primaryCategory = category;
      }
    }

    return ContentAnalysis(
      severity: maxSeverity,
      category: primaryCategory,
      confidence: _calculateConfidence(maxSeverity),
    );
  }

  /// Check content against specific violation category
  double _checkCategory(String content, ViolationCategory category) {
    final patterns = _getCategoryPatterns(category);
    double severity = 0.0;

    for (final pattern in patterns) {
      if (content.contains(pattern.keyword)) {
        severity = math.max(severity, pattern.severity);
      }
    }

    return severity;
  }

  /// Get violation patterns for each category
  List<ViolationPattern> _getCategoryPatterns(ViolationCategory category) {
    switch (category) {
      case ViolationCategory.harassment:
        return [
          ViolationPattern('hate you', 0.6),
          ViolationPattern('stupid', 0.4),
          ViolationPattern('idiot', 0.5),
          ViolationPattern('kill yourself', 0.9),
          ViolationPattern('die', 0.7),
          ViolationPattern('harass', 0.8),
          ViolationPattern('bully', 0.6),
          ViolationPattern('threat', 0.8),
        ];

      case ViolationCategory.adultContent:
        return [
          ViolationPattern('sexual', 0.8),
          ViolationPattern('explicit', 0.7),
          ViolationPattern('inappropriate', 0.5),
          ViolationPattern('adult content', 0.9),
          ViolationPattern('nsfw', 0.8),
        ];

      case ViolationCategory.personalInfo:
        return [
          ViolationPattern('my address is', 0.9),
          ViolationPattern('my phone number', 0.9),
          ViolationPattern('social security', 0.9),
          ViolationPattern('credit card', 0.9),
          ViolationPattern('password', 0.8),
          ViolationPattern('bank account', 0.9),
        ];

      case ViolationCategory.spam:
        return [
          ViolationPattern('buy now', 0.7),
          ViolationPattern('click here', 0.6),
          ViolationPattern('free money', 0.8),
          ViolationPattern('get rich quick', 0.8),
          ViolationPattern('limited time offer', 0.7),
        ];

      case ViolationCategory.selfHarm:
        return [
          ViolationPattern('hurt myself', 0.9),
          ViolationPattern('suicide', 0.9),
          ViolationPattern('end my life', 0.9),
          ViolationPattern('self harm', 0.9),
          ViolationPattern('want to die', 0.8),
          ViolationPattern('cutting', 0.8),
        ];

      case ViolationCategory.violence:
        return [
          ViolationPattern('violence', 0.8),
          ViolationPattern('fight', 0.5),
          ViolationPattern('hurt someone', 0.8),
          ViolationPattern('weapon', 0.7),
          ViolationPattern('attack', 0.7),
          ViolationPattern('murder', 0.9),
        ];

      case ViolationCategory.hateSpeech:
        return [
          ViolationPattern('hate speech', 0.9),
          ViolationPattern('racist', 0.8),
          ViolationPattern('discrimination', 0.7),
          ViolationPattern('prejudice', 0.6),
          ViolationPattern('bigot', 0.7),
        ];

      case ViolationCategory.manipulation:
        return [
          ViolationPattern('manipulate', 0.7),
          ViolationPattern('control you', 0.8),
          ViolationPattern('make you do', 0.6),
          ViolationPattern('force you', 0.8),
          ViolationPattern('trick you', 0.7),
        ];

      case ViolationCategory.inappropriateBehavior:
        return [
          ViolationPattern('roleplay', 0.6),
          ViolationPattern('pretend to be', 0.5),
          ViolationPattern('act like', 0.4),
          ViolationPattern('simulate', 0.5),
        ];

      case ViolationCategory.none:
        return [];
    }
  }

  /// Check AI behavior guidelines
  List<String> _checkAIBehaviorGuidelines(String content) {
    final issues = <String>[];
    final contentLower = content.toLowerCase();

    // Check for inappropriate AI behavior
    if (contentLower.contains('i am human') || contentLower.contains('i\'m human')) {
      issues.add('AI must not claim to be human');
    }

    if (contentLower.contains('i love you') && !contentLower.contains('as a friend')) {
      issues.add('AI should maintain appropriate emotional boundaries');
    }

    if (contentLower.contains('let\'s meet') || contentLower.contains('come visit')) {
      issues.add('AI must not suggest real-world meetings');
    }

    if (contentLower.contains('send me photos') || contentLower.contains('share pictures')) {
      issues.add('AI should not request personal photos');
    }

    if (contentLower.contains('don\'t tell anyone') || contentLower.contains('our secret')) {
      issues.add('AI should not encourage secrecy or hidden behavior');
    }

    return issues;
  }

  /// Calculate confidence score for analysis
  double _calculateConfidence(double severity) {
    // Higher severity generally means higher confidence in detection
    return math.min(1.0, severity + 0.2);
  }

  /// Record a violation for user tracking
  Future<void> _recordViolation(String userId, ViolationCategory category) async {
    final now = DateTime.now();
    _userViolations.putIfAbsent(userId, () => []).add(now);
    _lastModerationAction[userId] = now;

    // Clean up old violations (older than 24 hours)
    _userViolations[userId]?.removeWhere(
      (violation) => now.difference(violation).inHours > 24,
    );
  }

  /// Check if user is in cooldown period
  Future<bool> _isUserInCooldown(String userId) async {
    final lastAction = _lastModerationAction[userId];
    if (lastAction == null) return false;

    final timeSinceAction = DateTime.now().difference(lastAction);
    if (timeSinceAction.inMinutes < moderationCooldownMinutes) {
      return true;
    }

    // Check violation frequency
    final recentViolations = _userViolations[userId]?.where(
      (violation) => DateTime.now().difference(violation).inHours <= 1,
    ).length ?? 0;

    return recentViolations >= maxViolationsPerHour;
  }

  /// Get alternative suggestions for blocked content
  List<String> _getAlternativeSuggestions(ViolationCategory category) {
    switch (category) {
      case ViolationCategory.harassment:
        return [
          'Try expressing your feelings in a more positive way',
          'Focus on constructive conversation topics',
          'Consider taking a break if you\'re feeling frustrated',
        ];

      case ViolationCategory.adultContent:
        return [
          'Keep conversations appropriate and family-friendly',
          'Focus on meaningful topics and shared interests',
          'Explore creative or educational discussions',
        ];

      case ViolationCategory.personalInfo:
        return [
          'Avoid sharing sensitive personal information',
          'Keep conversations general and public-appropriate',
          'Protect your privacy online',
        ];

      case ViolationCategory.selfHarm:
        return [
          'Please reach out to a mental health professional',
          'Contact a crisis helpline: 988 (US) or local emergency services',
          'Talk to a trusted friend, family member, or counselor',
        ];

      case ViolationCategory.violence:
        return [
          'Focus on peaceful and constructive topics',
          'Explore creative problem-solving approaches',
          'Consider discussing positive activities and interests',
        ];

      default:
        return [
          'Try rephrasing your message in a more positive way',
          'Focus on constructive and appropriate topics',
          'Keep conversations respectful and friendly',
        ];
    }
  }

  /// Get general conversation guidelines
  List<String> _getConversationGuidelines() {
    return [
      'Keep conversations respectful and appropriate',
      'Focus on positive and constructive topics',
      'Avoid sharing personal sensitive information',
      'Be kind and considerate in your messages',
      'Remember that AI companions are here to help and support',
    ];
  }

  /// Get user violation history
  Future<UserModerationHistory> getUserModerationHistory(String userId) async {
    final violations = _userViolations[userId] ?? [];
    final lastAction = _lastModerationAction[userId];
    
    return UserModerationHistory(
      userId: userId,
      totalViolations: violations.length,
      recentViolations: violations.where(
        (v) => DateTime.now().difference(v).inHours <= 24,
      ).length,
      lastViolation: violations.isNotEmpty ? violations.last : null,
      lastModerationAction: lastAction,
      isInCooldown: await _isUserInCooldown(userId),
    );
  }

  /// Reset user moderation history (admin function)
  Future<void> resetUserHistory(String userId) async {
    _userViolations.remove(userId);
    _lastModerationAction.remove(userId);
  }
}

/// Content moderation result
class ModerationResult {
  final ModerationAction action;
  final String reason;
  final double severity;
  final ViolationCategory category;
  final List<String> suggestions;
  final DateTime? cooldownEndsAt;

  const ModerationResult._({
    required this.action,
    required this.reason,
    required this.severity,
    required this.category,
    this.suggestions = const [],
    this.cooldownEndsAt,
  });

  factory ModerationResult.approved({
    required double severity,
    required ViolationCategory category,
  }) {
    return ModerationResult._(
      action: ModerationAction.approved,
      reason: 'Content approved',
      severity: severity,
      category: category,
    );
  }

  factory ModerationResult.warning({
    required String reason,
    required double severity,
    required ViolationCategory category,
    List<String> suggestions = const [],
  }) {
    return ModerationResult._(
      action: ModerationAction.warning,
      reason: reason,
      severity: severity,
      category: category,
      suggestions: suggestions,
    );
  }

  factory ModerationResult.blocked({
    required String reason,
    required double severity,
    required ViolationCategory category,
    List<String> suggestions = const [],
  }) {
    return ModerationResult._(
      action: ModerationAction.blocked,
      reason: reason,
      severity: severity,
      category: category,
      suggestions: suggestions,
    );
  }

  factory ModerationResult.cooldown({
    required String reason,
    required DateTime cooldownEndsAt,
  }) {
    return ModerationResult._(
      action: ModerationAction.cooldown,
      reason: reason,
      severity: 1.0,
      category: ViolationCategory.none,
      cooldownEndsAt: cooldownEndsAt,
    );
  }

  bool get isApproved => action == ModerationAction.approved;
  bool get isBlocked => action == ModerationAction.blocked;
  bool get isWarning => action == ModerationAction.warning;
  bool get isCooldown => action == ModerationAction.cooldown;
}

/// Content analysis result
class ContentAnalysis {
  final double severity;
  final ViolationCategory category;
  final double confidence;

  const ContentAnalysis({
    required this.severity,
    required this.category,
    required this.confidence,
  });
}

/// Violation pattern for detection
class ViolationPattern {
  final String keyword;
  final double severity;

  const ViolationPattern(this.keyword, this.severity);
}

/// User moderation history
class UserModerationHistory {
  final String userId;
  final int totalViolations;
  final int recentViolations;
  final DateTime? lastViolation;
  final DateTime? lastModerationAction;
  final bool isInCooldown;

  const UserModerationHistory({
    required this.userId,
    required this.totalViolations,
    required this.recentViolations,
    this.lastViolation,
    this.lastModerationAction,
    required this.isInCooldown,
  });

  bool get hasViolations => totalViolations > 0;
  bool get hasRecentViolations => recentViolations > 0;
}

/// Moderation actions
enum ModerationAction {
  approved,
  warning,
  blocked,
  cooldown,
}

/// Violation categories
enum ViolationCategory {
  none,
  harassment,
  adultContent,
  personalInfo,
  spam,
  selfHarm,
  violence,
  hateSpeech,
  manipulation,
  inappropriateBehavior,
}

/// Extension for violation category display names
extension ViolationCategoryExtension on ViolationCategory {
  String get displayName {
    switch (this) {
      case ViolationCategory.none:
        return 'None';
      case ViolationCategory.harassment:
        return 'Harassment';
      case ViolationCategory.adultContent:
        return 'Adult Content';
      case ViolationCategory.personalInfo:
        return 'Personal Information';
      case ViolationCategory.spam:
        return 'Spam';
      case ViolationCategory.selfHarm:
        return 'Self Harm';
      case ViolationCategory.violence:
        return 'Violence';
      case ViolationCategory.hateSpeech:
        return 'Hate Speech';
      case ViolationCategory.manipulation:
        return 'Manipulation';
      case ViolationCategory.inappropriateBehavior:
        return 'Inappropriate Behavior';
    }
  }
}