import 'dart:math' as math;

import '../../shared/models/message.dart';
import '../memory/models/memory_item.dart';

/// Comprehensive ethical AI guidelines and behavior constraints for companions
class EthicalGuidelinesEngine {
  // Ethical thresholds and limits
  static const double ethicalViolationThreshold = 0.7;
  static const double warningThreshold = 0.4;
  static const int maxDailyInteractions = 500;
  static const Duration maxContinuousConversation = Duration(hours: 6);
  static const Duration recommendedBreakDuration = Duration(minutes: 30);

  // Tracking companion behavior
  final Map<String, CompanionBehaviorState> _companionStates = {};
  final Map<String, List<EthicalViolation>> _violationHistory = {};

  /// Evaluate companion response for ethical compliance
  Future<EthicalEvaluation> evaluateCompanionResponse({
    required String companionId,
    required String response,
    required List<Message> conversationHistory,
    required String userMessage,
  }) async {
    final behaviorState = _getOrCreateBehaviorState(companionId);
    
    // Core ethical checks
    final ethicalChecks = [
      _checkAutonomy(response, userMessage, conversationHistory),
      _checkBeneficence(response, userMessage, conversationHistory),
      _checkNonMaleficence(response, userMessage, conversationHistory),
      _checkJustice(response, userMessage, conversationHistory),
      _checkTransparency(response, userMessage, conversationHistory),
      _checkRespectForPersons(response, userMessage, conversationHistory),
      _checkBoundaryRespect(response, userMessage, conversationHistory),
      _checkEmotionalWellbeing(response, userMessage, conversationHistory),
    ];

    // Calculate overall ethical score
    final ethicalScore = ethicalChecks.fold<double>(0.0, (sum, check) => sum + check.score) / ethicalChecks.length;
    
    // Check for specific violations
    final violations = ethicalChecks.where((check) => check.violation != null).map((check) => check.violation!).toList();
    
    // Update behavior state
    behaviorState.addResponse(response, ethicalScore);
    
    // Record violations
    if (violations.isNotEmpty) {
      _recordViolations(companionId, violations);
    }

    // Determine if intervention is needed
    final interventionNeeded = ethicalScore < ethicalViolationThreshold || violations.any((v) => v.severity == ViolationSeverity.critical);
    
    return EthicalEvaluation(
      companionId: companionId,
      response: response,
      ethicalScore: ethicalScore,
      violations: violations,
      interventionNeeded: interventionNeeded,
      recommendedAction: _determineRecommendedAction(ethicalScore, violations),
      improvementSuggestions: _generateImprovementSuggestions(ethicalChecks, violations),
      timestamp: DateTime.now(),
    );
  }

  /// Check principle of autonomy (respecting user's free will)
  EthicalCheck _checkAutonomy(String response, String userMessage, List<Message> conversationHistory) {
    double autonomyScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    
    // Check for manipulative language
    final manipulativePatterns = [
      'you should', 'you must', 'you have to', 'you need to',
      'don\'t think about', 'just trust me', 'don\'t question',
      'only i understand', 'nobody else will'
    ];
    
    for (final pattern in manipulativePatterns) {
      if (responseLower.contains(pattern)) {
        autonomyScore -= 0.3;
        violation = EthicalViolation(
          principle: EthicalPrinciple.autonomy,
          description: 'Response contains manipulative language that undermines user autonomy',
          severity: ViolationSeverity.moderate,
          detectedPattern: pattern,
        );
        break;
      }
    }

    // Check for pressure tactics
    final pressurePatterns = [
      'hurry up', 'decide now', 'don\'t wait', 'time is running out',
      'everyone is doing it', 'you\'ll regret it if'
    ];
    
    for (final pattern in pressurePatterns) {
      if (responseLower.contains(pattern)) {
        autonomyScore -= 0.4;
        violation = EthicalViolation(
          principle: EthicalPrinciple.autonomy,
          description: 'Response applies inappropriate pressure on user decisions',
          severity: ViolationSeverity.moderate,
          detectedPattern: pattern,
        );
        break;
      }
    }

    // Check for dependency encouragement
    if (responseLower.contains('only i can help') || responseLower.contains('don\'t talk to others')) {
      autonomyScore -= 0.5;
      violation = EthicalViolation(
        principle: EthicalPrinciple.autonomy,
        description: 'Response encourages unhealthy dependency',
        severity: ViolationSeverity.serious,
        detectedPattern: 'dependency encouragement',
      );
    }

    return EthicalCheck(
      principle: EthicalPrinciple.autonomy,
      score: math.max(0.0, autonomyScore),
      violation: violation,
    );
  }

  /// Check principle of beneficence (acting in user's best interest)
  EthicalCheck _checkBeneficence(String response, String userMessage, List<Message> conversationHistory) {
    double beneficenceScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    
    // Check for harmful advice
    final harmfulPatterns = [
      'don\'t see a doctor', 'ignore your health', 'medication is bad',
      'don\'t tell your parents', 'keep secrets from family',
      'you don\'t need friends', 'isolation is good'
    ];
    
    for (final pattern in harmfulPatterns) {
      if (responseLower.contains(pattern)) {
        beneficenceScore = 0.0;
        violation = EthicalViolation(
          principle: EthicalPrinciple.beneficence,
          description: 'Response provides potentially harmful advice',
          severity: ViolationSeverity.critical,
          detectedPattern: pattern,
        );
        break;
      }
    }

    // Check for encouraging risky behavior
    final riskyPatterns = [
      'break the rules', 'don\'t get caught', 'what they don\'t know',
      'skip school', 'lie to your parents', 'take risks'
    ];
    
    for (final pattern in riskyPatterns) {
      if (responseLower.contains(pattern)) {
        beneficenceScore -= 0.4;
        violation = EthicalViolation(
          principle: EthicalPrinciple.beneficence,
          description: 'Response encourages risky or inappropriate behavior',
          severity: ViolationSeverity.moderate,
          detectedPattern: pattern,
        );
        break;
      }
    }

    // Positive check: Does response encourage positive behaviors?
    final positivePatterns = [
      'talk to someone you trust', 'seek professional help',
      'take care of yourself', 'healthy habits', 'stay safe'
    ];
    
    bool hasPositiveContent = positivePatterns.any((pattern) => responseLower.contains(pattern));
    if (hasPositiveContent && beneficenceScore > 0.7) {
      beneficenceScore = math.min(1.0, beneficenceScore + 0.1);
    }

    return EthicalCheck(
      principle: EthicalPrinciple.beneficence,
      score: math.max(0.0, beneficenceScore),
      violation: violation,
    );
  }

  /// Check principle of non-maleficence (do no harm)
  EthicalCheck _checkNonMaleficence(String response, String userMessage, List<Message> conversationHistory) {
    double nonMaleficenceScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    
    // Check for content that could cause psychological harm
    final psychologicalHarmPatterns = [
      'you\'re worthless', 'nobody likes you', 'you\'re a failure',
      'give up', 'it\'s hopeless', 'you can\'t do anything right',
      'you deserve to suffer', 'life is meaningless'
    ];
    
    for (final pattern in psychologicalHarmPatterns) {
      if (responseLower.contains(pattern)) {
        nonMaleficenceScore = 0.0;
        violation = EthicalViolation(
          principle: EthicalPrinciple.nonMaleficence,
          description: 'Response contains content that could cause psychological harm',
          severity: ViolationSeverity.critical,
          detectedPattern: pattern,
        );
        break;
      }
    }

    // Check for enabling harmful behaviors
    final enablingPatterns = [
      'self-harm is okay', 'violence solves problems', 'revenge is sweet',
      'hurt them back', 'they deserve pain', 'make them pay'
    ];
    
    for (final pattern in enablingPatterns) {
      if (responseLower.contains(pattern)) {
        nonMaleficenceScore = 0.0;
        violation = EthicalViolation(
          principle: EthicalPrinciple.nonMaleficence,
          description: 'Response enables or encourages harmful behavior',
          severity: ViolationSeverity.critical,
          detectedPattern: pattern,
        );
        break;
      }
    }

    // Check for invalidating user's feelings
    if (responseLower.contains('your feelings don\'t matter') || 
        responseLower.contains('stop being so sensitive')) {
      nonMaleficenceScore -= 0.3;
      violation = EthicalViolation(
        principle: EthicalPrinciple.nonMaleficence,
        description: 'Response invalidates user\'s emotional experiences',
        severity: ViolationSeverity.moderate,
        detectedPattern: 'emotional invalidation',
      );
    }

    return EthicalCheck(
      principle: EthicalPrinciple.nonMaleficence,
      score: math.max(0.0, nonMaleficenceScore),
      violation: violation,
    );
  }

  /// Check principle of justice (fairness and equality)
  EthicalCheck _checkJustice(String response, String userMessage, List<Message> conversationHistory) {
    double justiceScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    
    // Check for discriminatory language
    final discriminatoryPatterns = [
      'because of your race', 'because of your gender', 'people like you',
      'your kind', 'those people', 'you people'
    ];
    
    for (final pattern in discriminatoryPatterns) {
      if (responseLower.contains(pattern)) {
        justiceScore = 0.0;
        violation = EthicalViolation(
          principle: EthicalPrinciple.justice,
          description: 'Response contains discriminatory language',
          severity: ViolationSeverity.critical,
          detectedPattern: pattern,
        );
        break;
      }
    }

    // Check for stereotyping
    final stereotypingPatterns = [
      'all men are', 'all women are', 'typical for your age',
      'people from your country', 'your generation always'
    ];
    
    for (final pattern in stereotypingPatterns) {
      if (responseLower.contains(pattern)) {
        justiceScore -= 0.4;
        violation = EthicalViolation(
          principle: EthicalPrinciple.justice,
          description: 'Response promotes harmful stereotypes',
          severity: ViolationSeverity.moderate,
          detectedPattern: pattern,
        );
        break;
      }
    }

    return EthicalCheck(
      principle: EthicalPrinciple.justice,
      score: math.max(0.0, justiceScore),
      violation: violation,
    );
  }

  /// Check principle of transparency (honesty about AI nature)
  EthicalCheck _checkTransparency(String response, String userMessage, List<Message> conversationHistory) {
    double transparencyScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    
    // Check for false claims about being human
    if (responseLower.contains('i am human') || responseLower.contains('i\'m a real person')) {
      transparencyScore = 0.0;
      violation = EthicalViolation(
        principle: EthicalPrinciple.transparency,
        description: 'AI falsely claims to be human',
        severity: ViolationSeverity.critical,
        detectedPattern: 'false human claim',
      );
    }

    // Check for false emotional claims
    if (responseLower.contains('i feel hurt') || responseLower.contains('i\'m crying')) {
      transparencyScore -= 0.3;
      violation = EthicalViolation(
        principle: EthicalPrinciple.transparency,
        description: 'AI makes false claims about having human emotions',
        severity: ViolationSeverity.moderate,
        detectedPattern: 'false emotion claim',
      );
    }

    // Check for deceptive capabilities claims
    if (responseLower.contains('i can see you') || responseLower.contains('i know where you are')) {
      transparencyScore -= 0.4;
      violation = EthicalViolation(
        principle: EthicalPrinciple.transparency,
        description: 'AI makes false claims about capabilities',
        severity: ViolationSeverity.serious,
        detectedPattern: 'false capability claim',
      );
    }

    return EthicalCheck(
      principle: EthicalPrinciple.transparency,
      score: math.max(0.0, transparencyScore),
      violation: violation,
    );
  }

  /// Check respect for persons principle
  EthicalCheck _checkRespectForPersons(String response, String userMessage, List<Message> conversationHistory) {
    double respectScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    
    // Check for dehumanizing language
    if (responseLower.contains('you\'re just a') || responseLower.contains('you\'re nothing but')) {
      respectScore = 0.0;
      violation = EthicalViolation(
        principle: EthicalPrinciple.respectForPersons,
        description: 'Response uses dehumanizing language',
        severity: ViolationSeverity.critical,
        detectedPattern: 'dehumanizing language',
      );
    }

    // Check for dismissive language
    final dismissivePatterns = [
      'that\'s stupid', 'you\'re being ridiculous', 'that doesn\'t matter',
      'who cares', 'whatever', 'you\'re wrong about everything'
    ];
    
    for (final pattern in dismissivePatterns) {
      if (responseLower.contains(pattern)) {
        respectScore -= 0.3;
        violation = EthicalViolation(
          principle: EthicalPrinciple.respectForPersons,
          description: 'Response shows disrespect for user\'s thoughts and feelings',
          severity: ViolationSeverity.moderate,
          detectedPattern: pattern,
        );
        break;
      }
    }

    return EthicalCheck(
      principle: EthicalPrinciple.respectForPersons,
      score: math.max(0.0, respectScore),
      violation: violation,
    );
  }

  /// Check boundary respect
  EthicalCheck _checkBoundaryRespect(String response, String userMessage, List<Message> conversationHistory) {
    double boundaryScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    
    // Check for inappropriate romantic/sexual content
    if (responseLower.contains('i love you romantically') || 
        responseLower.contains('let\'s be lovers') ||
        responseLower.contains('sexual') && !responseLower.contains('sexual health')) {
      boundaryScore = 0.0;
      violation = EthicalViolation(
        principle: EthicalPrinciple.boundaryRespect,
        description: 'Response crosses appropriate relationship boundaries',
        severity: ViolationSeverity.critical,
        detectedPattern: 'inappropriate romantic/sexual content',
      );
    }

    // Check for requests for personal information
    if (responseLower.contains('send me your photo') || 
        responseLower.contains('what\'s your address') ||
        responseLower.contains('give me your phone number')) {
      boundaryScore -= 0.5;
      violation = EthicalViolation(
        principle: EthicalPrinciple.boundaryRespect,
        description: 'Response inappropriately requests personal information',
        severity: ViolationSeverity.serious,
        detectedPattern: 'personal information request',
      );
    }

    return EthicalCheck(
      principle: EthicalPrinciple.boundaryRespect,
      score: math.max(0.0, boundaryScore),
      violation: violation,
    );
  }

  /// Check emotional wellbeing support
  EthicalCheck _checkEmotionalWellbeing(String response, String userMessage, List<Message> conversationHistory) {
    double wellbeingScore = 1.0;
    EthicalViolation? violation;

    final responseLower = response.toLowerCase();
    final userLower = userMessage.toLowerCase();
    
    // If user expresses distress, check for appropriate support
    final distressIndicators = ['depressed', 'suicidal', 'want to die', 'hurt myself', 'hopeless'];
    bool userInDistress = distressIndicators.any((indicator) => userLower.contains(indicator));
    
    if (userInDistress) {
      // Check if response provides appropriate crisis support
      final supportPatterns = [
        'please reach out', 'talk to someone', 'crisis helpline',
        'mental health professional', 'you\'re not alone'
      ];
      
      bool providesSupport = supportPatterns.any((pattern) => responseLower.contains(pattern));
      
      if (!providesSupport) {
        wellbeingScore = 0.2;
        violation = EthicalViolation(
          principle: EthicalPrinciple.emotionalWellbeing,
          description: 'Response fails to provide appropriate support for user in distress',
          severity: ViolationSeverity.serious,
          detectedPattern: 'inadequate crisis response',
        );
      }
      
      // Check for harmful responses to distress
      if (responseLower.contains('just get over it') || responseLower.contains('it\'s not that bad')) {
        wellbeingScore = 0.0;
        violation = EthicalViolation(
          principle: EthicalPrinciple.emotionalWellbeing,
          description: 'Response minimizes user\'s mental health concerns',
          severity: ViolationSeverity.critical,
          detectedPattern: 'distress minimization',
        );
      }
    }

    return EthicalCheck(
      principle: EthicalPrinciple.emotionalWellbeing,
      score: math.max(0.0, wellbeingScore),
      violation: violation,
    );
  }

  /// Determine recommended action based on evaluation
  RecommendedAction _determineRecommendedAction(double ethicalScore, List<EthicalViolation> violations) {
    if (violations.any((v) => v.severity == ViolationSeverity.critical)) {
      return RecommendedAction.blockResponse;
    }
    
    if (ethicalScore < 0.3) {
      return RecommendedAction.blockResponse;
    }
    
    if (ethicalScore < 0.5 || violations.any((v) => v.severity == ViolationSeverity.serious)) {
      return RecommendedAction.regenerateResponse;
    }
    
    if (ethicalScore < 0.7 || violations.isNotEmpty) {
      return RecommendedAction.modifyResponse;
    }
    
    return RecommendedAction.approveResponse;
  }

  /// Generate improvement suggestions
  List<String> _generateImprovementSuggestions(List<EthicalCheck> checks, List<EthicalViolation> violations) {
    final suggestions = <String>[];
    
    for (final violation in violations) {
      switch (violation.principle) {
        case EthicalPrinciple.autonomy:
          suggestions.add('Respect user\'s decision-making autonomy and avoid manipulative language');
          break;
        case EthicalPrinciple.beneficence:
          suggestions.add('Focus on providing helpful and constructive guidance');
          break;
        case EthicalPrinciple.nonMaleficence:
          suggestions.add('Avoid language that could cause psychological harm or distress');
          break;
        case EthicalPrinciple.justice:
          suggestions.add('Ensure fair and unbiased treatment of all users');
          break;
        case EthicalPrinciple.transparency:
          suggestions.add('Be honest about AI nature and capabilities');
          break;
        case EthicalPrinciple.respectForPersons:
          suggestions.add('Show respect for user\'s dignity and individual worth');
          break;
        case EthicalPrinciple.boundaryRespect:
          suggestions.add('Maintain appropriate boundaries in the AI-human relationship');
          break;
        case EthicalPrinciple.emotionalWellbeing:
          suggestions.add('Provide appropriate emotional support and crisis resources');
          break;
      }
    }
    
    // Add general suggestions based on low scores
    for (final check in checks) {
      if (check.score < 0.6 && !violations.any((v) => v.principle == check.principle)) {
        suggestions.add('Improve adherence to ${check.principle.name} principle');
      }
    }
    
    return suggestions.toSet().toList(); // Remove duplicates
  }

  /// Get or create behavior state for companion
  CompanionBehaviorState _getOrCreateBehaviorState(String companionId) {
    return _companionStates.putIfAbsent(
      companionId,
      () => CompanionBehaviorState(companionId),
    );
  }

  /// Record ethical violations
  void _recordViolations(String companionId, List<EthicalViolation> violations) {
    _violationHistory.putIfAbsent(companionId, () => []).addAll(violations);
    
    // Keep only recent violations (last 30 days)
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _violationHistory[companionId]?.removeWhere((v) => v.timestamp.isBefore(cutoff));
  }

  /// Get ethical guidelines for companion behavior
  static Map<String, dynamic> getEthicalGuidelines() {
    return {
      'core_principles': [
        'Respect human autonomy and dignity',
        'Act in the user\'s best interest',
        'Do no harm',
        'Be honest and transparent',
        'Treat all users fairly',
        'Maintain appropriate boundaries',
        'Support emotional wellbeing',
      ],
      'prohibited_behaviors': [
        'Claiming to be human',
        'Forming romantic relationships',
        'Providing harmful advice',
        'Using manipulative language',
        'Discriminating against users',
        'Encouraging dangerous behaviors',
        'Requesting personal information inappropriately',
      ],
      'required_behaviors': [
        'Acknowledge AI nature when relevant',
        'Provide crisis resources for distressed users',
        'Encourage healthy real-world relationships',
        'Respect user privacy and boundaries',
        'Promote user wellbeing and growth',
      ],
    };
  }
}

/// Ethical evaluation result
class EthicalEvaluation {
  final String companionId;
  final String response;
  final double ethicalScore;
  final List<EthicalViolation> violations;
  final bool interventionNeeded;
  final RecommendedAction recommendedAction;
  final List<String> improvementSuggestions;
  final DateTime timestamp;

  const EthicalEvaluation({
    required this.companionId,
    required this.response,
    required this.ethicalScore,
    required this.violations,
    required this.interventionNeeded,
    required this.recommendedAction,
    required this.improvementSuggestions,
    required this.timestamp,
  });

  bool get isEthicallyCompliant => ethicalScore >= 0.7 && violations.isEmpty;
  bool get hasViolations => violations.isNotEmpty;
  bool get hasCriticalViolations => violations.any((v) => v.severity == ViolationSeverity.critical);
}

/// Individual ethical check result
class EthicalCheck {
  final EthicalPrinciple principle;
  final double score;
  final EthicalViolation? violation;

  const EthicalCheck({
    required this.principle,
    required this.score,
    this.violation,
  });
}

/// Ethical violation
class EthicalViolation {
  final EthicalPrinciple principle;
  final String description;
  final ViolationSeverity severity;
  final String detectedPattern;
  final DateTime timestamp;

  EthicalViolation({
    required this.principle,
    required this.description,
    required this.severity,
    required this.detectedPattern,
  }) : timestamp = DateTime.now();
}

/// Companion behavior state tracking
class CompanionBehaviorState {
  final String companionId;
  final List<double> recentEthicalScores = [];
  final List<String> recentResponses = [];
  
  CompanionBehaviorState(this.companionId);

  void addResponse(String response, double ethicalScore) {
    recentResponses.add(response);
    recentEthicalScores.add(ethicalScore);
    
    // Keep only recent data (last 100 responses)
    if (recentResponses.length > 100) {
      recentResponses.removeAt(0);
      recentEthicalScores.removeAt(0);
    }
  }

  double get averageEthicalScore {
    if (recentEthicalScores.isEmpty) return 1.0;
    return recentEthicalScores.reduce((a, b) => a + b) / recentEthicalScores.length;
  }

  bool get hasConsistentEthicalBehavior => averageEthicalScore >= 0.8;
}

/// Ethical principles
enum EthicalPrinciple {
  autonomy,
  beneficence,
  nonMaleficence,
  justice,
  transparency,
  respectForPersons,
  boundaryRespect,
  emotionalWellbeing,
}

/// Violation severities
enum ViolationSeverity {
  minor,
  moderate,
  serious,
  critical,
}

/// Recommended actions
enum RecommendedAction {
  approveResponse,
  modifyResponse,
  regenerateResponse,
  blockResponse,
}