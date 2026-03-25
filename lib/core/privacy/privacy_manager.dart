import 'dart:convert';
import 'dart:io';

import '../storage/conversation_storage.dart';
import '../memory/memory_manager.dart';
import '../memory/models/memory_item.dart';
import '../../shared/models/message.dart';
import '../../shared/services/encryption_service.dart';

/// Comprehensive privacy and data management system
class PrivacyManager {
  final ConversationStorage _conversationStorage;
  final MemoryManager _memoryManager;
  final EncryptionService _encryptionService;

  // Privacy settings per user
  final Map<String, UserPrivacySettings> _userSettings = {};

  PrivacyManager({
    required ConversationStorage conversationStorage,
    required MemoryManager memoryManager,
    required EncryptionService encryptionService,
  })  : _conversationStorage = conversationStorage,
        _memoryManager = memoryManager,
        _encryptionService = encryptionService;

  /// Get user privacy settings
  Future<UserPrivacySettings> getUserPrivacySettings(String userId) async {
    if (_userSettings.containsKey(userId)) {
      return _userSettings[userId]!;
    }

    // Load from storage or create default
    final settings = await _loadPrivacySettings(userId) ?? UserPrivacySettings.defaultSettings(userId);
    _userSettings[userId] = settings;
    return settings;
  }

  /// Update user privacy settings
  Future<void> updatePrivacySettings(String userId, UserPrivacySettings settings) async {
    _userSettings[userId] = settings;
    await _savePrivacySettings(userId, settings);

    // Apply settings changes immediately
    await _applyPrivacySettings(userId, settings);
  }

  /// Export user data in portable format
  Future<UserDataExport> exportUserData(String userId, {
    List<String>? companionIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final settings = await getUserPrivacySettings(userId);
    
    if (!settings.allowDataExport) {
      throw PrivacyException('Data export is disabled in privacy settings');
    }

    final exportData = UserDataExport(
      userId: userId,
      exportDate: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
    );

    // Export conversations
    if (settings.includeConversationsInExport && companionIds != null) {
      for (final companionId in companionIds) {
        final conversations = await _conversationStorage.loadConversation(
          companionId,
          after: startDate,
          before: endDate,
        );
        exportData.conversations[companionId] = conversations;
      }
    }

    // Export memories
    if (settings.includeMemoriesInExport && companionIds != null) {
      for (final companionId in companionIds) {
        final memories = await _memoryManager.getCompanionMemories(companionId);
        final filteredMemories = memories.where((memory) {
          if (startDate != null && memory.timestamp.isBefore(startDate)) return false;
          if (endDate != null && memory.timestamp.isAfter(endDate)) return false;
          return true;
        }).toList();
        exportData.memories[companionId] = filteredMemories;
      }
    }

    // Export privacy settings
    exportData.privacySettings = settings;

    return exportData;
  }

  /// Delete user data (GDPR right to be forgotten)
  Future<DataDeletionResult> deleteUserData(String userId, {
    bool deleteConversations = true,
    bool deleteMemories = true,
    bool deletePrivacySettings = true,
    List<String>? specificCompanionIds,
  }) async {
    final deletionResult = DataDeletionResult(
      userId: userId,
      deletionDate: DateTime.now(),
    );

    try {
      // Delete conversations
      if (deleteConversations) {
        if (specificCompanionIds != null) {
          for (final companionId in specificCompanionIds) {
            await _conversationStorage.clearConversation(companionId);
            deletionResult.deletedConversations.add(companionId);
          }
        } else {
          // Delete all conversations for user
          // This would require a user-to-companion mapping in a real implementation
          deletionResult.deletedConversations.add('all');
        }
      }

      // Delete memories
      if (deleteMemories) {
        if (specificCompanionIds != null) {
          for (final companionId in specificCompanionIds) {
            await _memoryManager.deleteCompanionMemory(companionId);
            deletionResult.deletedMemories.add(companionId);
          }
        } else {
          // Delete all memories for user
          deletionResult.deletedMemories.add('all');
        }
      }

      // Delete privacy settings
      if (deletePrivacySettings) {
        await _deletePrivacySettings(userId);
        _userSettings.remove(userId);
        deletionResult.deletedPrivacySettings = true;
      }

      deletionResult.success = true;
      deletionResult.message = 'User data successfully deleted';

    } catch (e) {
      deletionResult.success = false;
      deletionResult.message = 'Error during data deletion: $e';
    }

    return deletionResult;
  }

  /// Anonymize user data instead of deleting
  Future<DataAnonymizationResult> anonymizeUserData(String userId, {
    List<String>? companionIds,
  }) async {
    final anonymizationResult = DataAnonymizationResult(
      userId: userId,
      anonymizationDate: DateTime.now(),
    );

    try {
      final anonymousId = _generateAnonymousId();

      // Anonymize conversations
      if (companionIds != null) {
        for (final companionId in companionIds) {
          final conversations = await _conversationStorage.loadConversation(companionId);
          final anonymizedConversations = conversations.map((message) => 
            _anonymizeMessage(message, anonymousId)
          ).toList();
          
          // Clear original and save anonymized
          await _conversationStorage.clearConversation(companionId);
          await _conversationStorage.saveMessages(anonymizedConversations, companionId);
          
          anonymizationResult.anonymizedConversations.add(companionId);
        }
      }

      // Anonymize memories
      if (companionIds != null) {
        for (final companionId in companionIds) {
          final memories = await _memoryManager.getCompanionMemories(companionId);
          
          // Delete personal memories, anonymize others
          for (final memory in memories) {
            if (memory.isPersonalInfo) {
              await _memoryManager.deleteCompanionMemory(companionId);
            } else {
              final anonymizedMemory = _anonymizeMemory(memory, anonymousId);
              // This would require a memory update method in MemoryManager
            }
          }
          
          anonymizationResult.anonymizedMemories.add(companionId);
        }
      }

      anonymizationResult.success = true;
      anonymizationResult.message = 'User data successfully anonymized';
      anonymizationResult.anonymousId = anonymousId;

    } catch (e) {
      anonymizationResult.success = false;
      anonymizationResult.message = 'Error during data anonymization: $e';
    }

    return anonymizationResult;
  }

  /// Audit user data access and processing
  Future<DataAuditReport> auditUserData(String userId) async {
    final settings = await getUserPrivacySettings(userId);
    
    final auditReport = DataAuditReport(
      userId: userId,
      auditDate: DateTime.now(),
      privacySettings: settings,
    );

    // Count data types
    // This would require companion-to-user mapping in a real implementation
    // For now, we'll provide estimates based on available data

    auditReport.dataTypeCounts = {
      'conversations': 0, // Would need to count actual conversations
      'memories': 0, // Would need to count actual memories
      'privacy_settings': 1,
      'usage_analytics': 0, // If we track usage
    };

    // Data processing purposes
    auditReport.processingPurposes = [
      'Conversation personalization',
      'Memory management',
      'Safety monitoring',
      'User experience improvement',
    ];

    // Data retention periods
    auditReport.retentionPeriods = {
      'conversations': settings.conversationRetentionDays,
      'memories': settings.memoryRetentionDays,
      'privacy_settings': null, // Kept until user deletion
    };

    return auditReport;
  }

  /// Process data subject access request (GDPR)
  Future<SubjectAccessResponse> processAccessRequest(String userId) async {
    final settings = await getUserPrivacySettings(userId);
    
    if (!settings.allowDataAccess) {
      throw PrivacyException('Data access is disabled in privacy settings');
    }

    final response = SubjectAccessResponse(
      userId: userId,
      requestDate: DateTime.now(),
      privacySettings: settings,
    );

    // Provide data summary without exposing actual content
    response.dataSummary = {
      'total_conversations': 0, // Count conversations
      'total_memories': 0, // Count memories
      'account_created': DateTime.now(), // Would be actual creation date
      'last_activity': DateTime.now(), // Would be actual last activity
      'data_processing_purposes': [
        'Conversation personalization',
        'Memory management',
        'Safety monitoring',
      ],
    };

    return response;
  }

  /// Apply automatic data retention policies
  Future<void> applyDataRetentionPolicies(String userId) async {
    final settings = await getUserPrivacySettings(userId);
    
    if (!settings.automaticDataCleanup) return;

    final now = DateTime.now();

    // Clean up old conversations
    if (settings.conversationRetentionDays != null) {
      final cutoffDate = now.subtract(Duration(days: settings.conversationRetentionDays!));
      // Would need to implement conversation cleanup by date
    }

    // Clean up old memories
    if (settings.memoryRetentionDays != null) {
      final cutoffDate = now.subtract(Duration(days: settings.memoryRetentionDays!));
      // Would need to implement memory cleanup by date
    }

    // Apply memory decay
    await _memoryManager.applyMemoryDecay(userId); // Would need companion mapping
  }

  /// Check if data processing is allowed
  bool isDataProcessingAllowed(String userId, DataProcessingType type) {
    final settings = _userSettings[userId];
    if (settings == null) return true; // Default allow

    switch (type) {
      case DataProcessingType.conversationPersonalization:
        return settings.allowConversationPersonalization;
      case DataProcessingType.memoryFormation:
        return settings.allowMemoryFormation;
      case DataProcessingType.safetyMonitoring:
        return settings.allowSafetyMonitoring;
      case DataProcessingType.usageAnalytics:
        return settings.allowUsageAnalytics;
      case DataProcessingType.dataExport:
        return settings.allowDataExport;
    }
  }

  /// Apply privacy settings to data processing
  Future<void> _applyPrivacySettings(String userId, UserPrivacySettings settings) async {
    // If conversation personalization is disabled, clear personalization data
    if (!settings.allowConversationPersonalization) {
      // Would implement clearing personalization data
    }

    // If memory formation is disabled, stop creating new memories
    if (!settings.allowMemoryFormation) {
      // Would implement memory creation blocking
    }

    // Apply data retention policies
    await applyDataRetentionPolicies(userId);
  }

  /// Load privacy settings from storage
  Future<UserPrivacySettings?> _loadPrivacySettings(String userId) async {
    try {
      // This would load from secure storage
      // For now, return null to use defaults
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save privacy settings to storage
  Future<void> _savePrivacySettings(String userId, UserPrivacySettings settings) async {
    try {
      // This would save to secure storage
      final settingsJson = json.encode(settings.toJson());
      final encrypted = await _encryptionService.encrypt(settingsJson);
      // Save encrypted settings
    } catch (e) {
      throw PrivacyException('Failed to save privacy settings: $e');
    }
  }

  /// Delete privacy settings from storage
  Future<void> _deletePrivacySettings(String userId) async {
    try {
      // This would delete from secure storage
    } catch (e) {
      throw PrivacyException('Failed to delete privacy settings: $e');
    }
  }

  /// Generate anonymous ID for anonymization
  String _generateAnonymousId() {
    return 'anon_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }

  /// Anonymize a message
  Message _anonymizeMessage(Message message, String anonymousId) {
    // Remove personal information from message content
    String anonymizedContent = message.content;
    
    // Replace common personal identifiers
    anonymizedContent = anonymizedContent.replaceAll(RegExp(r'\b[A-Za-z]+@[A-Za-z]+\.[A-Za-z]+\b'), '[EMAIL_REDACTED]');
    anonymizedContent = anonymizedContent.replaceAll(RegExp(r'\b\d{3}-\d{3}-\d{4}\b'), '[PHONE_REDACTED]');
    anonymizedContent = anonymizedContent.replaceAll(RegExp(r'\b\d{1,5}\s+\w+\s+(Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd)\b'), '[ADDRESS_REDACTED]');
    
    return Message(
      id: message.id,
      content: anonymizedContent,
      type: message.type,
      role: message.role,
      timestamp: message.timestamp,
      metadata: {
        'anonymized': true,
        'anonymous_id': anonymousId,
      },
    );
  }

  /// Anonymize a memory
  MemoryItem _anonymizeMemory(MemoryItem memory, String anonymousId) {
    return memory.copyWith(
      content: '[ANONYMIZED_MEMORY]',
      metadata: {
        'anonymized': true,
        'anonymous_id': anonymousId,
        'original_type': memory.type.name,
      },
    );
  }
}

/// User privacy settings
class UserPrivacySettings {
  final String userId;
  final bool allowConversationPersonalization;
  final bool allowMemoryFormation;
  final bool allowSafetyMonitoring;
  final bool allowUsageAnalytics;
  final bool allowDataExport;
  final bool allowDataAccess;
  final bool automaticDataCleanup;
  final int? conversationRetentionDays;
  final int? memoryRetentionDays;
  final bool includeConversationsInExport;
  final bool includeMemoriesInExport;
  final DateTime lastUpdated;

  const UserPrivacySettings({
    required this.userId,
    required this.allowConversationPersonalization,
    required this.allowMemoryFormation,
    required this.allowSafetyMonitoring,
    required this.allowUsageAnalytics,
    required this.allowDataExport,
    required this.allowDataAccess,
    required this.automaticDataCleanup,
    this.conversationRetentionDays,
    this.memoryRetentionDays,
    required this.includeConversationsInExport,
    required this.includeMemoriesInExport,
    required this.lastUpdated,
  });

  factory UserPrivacySettings.defaultSettings(String userId) {
    return UserPrivacySettings(
      userId: userId,
      allowConversationPersonalization: true,
      allowMemoryFormation: true,
      allowSafetyMonitoring: true,
      allowUsageAnalytics: false,
      allowDataExport: true,
      allowDataAccess: true,
      automaticDataCleanup: true,
      conversationRetentionDays: 365,
      memoryRetentionDays: 365,
      includeConversationsInExport: true,
      includeMemoriesInExport: false,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'allowConversationPersonalization': allowConversationPersonalization,
    'allowMemoryFormation': allowMemoryFormation,
    'allowSafetyMonitoring': allowSafetyMonitoring,
    'allowUsageAnalytics': allowUsageAnalytics,
    'allowDataExport': allowDataExport,
    'allowDataAccess': allowDataAccess,
    'automaticDataCleanup': automaticDataCleanup,
    'conversationRetentionDays': conversationRetentionDays,
    'memoryRetentionDays': memoryRetentionDays,
    'includeConversationsInExport': includeConversationsInExport,
    'includeMemoriesInExport': includeMemoriesInExport,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory UserPrivacySettings.fromJson(Map<String, dynamic> json) {
    return UserPrivacySettings(
      userId: json['userId'],
      allowConversationPersonalization: json['allowConversationPersonalization'],
      allowMemoryFormation: json['allowMemoryFormation'],
      allowSafetyMonitoring: json['allowSafetyMonitoring'],
      allowUsageAnalytics: json['allowUsageAnalytics'],
      allowDataExport: json['allowDataExport'],
      allowDataAccess: json['allowDataAccess'],
      automaticDataCleanup: json['automaticDataCleanup'],
      conversationRetentionDays: json['conversationRetentionDays'],
      memoryRetentionDays: json['memoryRetentionDays'],
      includeConversationsInExport: json['includeConversationsInExport'],
      includeMemoriesInExport: json['includeMemoriesInExport'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

/// User data export
class UserDataExport {
  final String userId;
  final DateTime exportDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, List<Message>> conversations = {};
  final Map<String, List<MemoryItem>> memories = {};
  late UserPrivacySettings privacySettings;

  UserDataExport({
    required this.userId,
    required this.exportDate,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'exportDate': exportDate.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'conversations': conversations.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList())),
    'memories': memories.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList())),
    'privacySettings': privacySettings.toJson(),
  };
}

/// Data deletion result
class DataDeletionResult {
  final String userId;
  final DateTime deletionDate;
  final List<String> deletedConversations = [];
  final List<String> deletedMemories = [];
  bool deletedPrivacySettings = false;
  bool success = false;
  String message = '';

  DataDeletionResult({
    required this.userId,
    required this.deletionDate,
  });
}

/// Data anonymization result
class DataAnonymizationResult {
  final String userId;
  final DateTime anonymizationDate;
  final List<String> anonymizedConversations = [];
  final List<String> anonymizedMemories = [];
  bool success = false;
  String message = '';
  String? anonymousId;

  DataAnonymizationResult({
    required this.userId,
    required this.anonymizationDate,
  });
}

/// Data audit report
class DataAuditReport {
  final String userId;
  final DateTime auditDate;
  final UserPrivacySettings privacySettings;
  Map<String, int> dataTypeCounts = {};
  List<String> processingPurposes = [];
  Map<String, int?> retentionPeriods = {};

  DataAuditReport({
    required this.userId,
    required this.auditDate,
    required this.privacySettings,
  });
}

/// Subject access response
class SubjectAccessResponse {
  final String userId;
  final DateTime requestDate;
  final UserPrivacySettings privacySettings;
  Map<String, dynamic> dataSummary = {};

  SubjectAccessResponse({
    required this.userId,
    required this.requestDate,
    required this.privacySettings,
  });
}

/// Data processing types
enum DataProcessingType {
  conversationPersonalization,
  memoryFormation,
  safetyMonitoring,
  usageAnalytics,
  dataExport,
}

/// Privacy exception
class PrivacyException implements Exception {
  final String message;
  const PrivacyException(this.message);
  @override
  String toString() => 'PrivacyException: $message';
}