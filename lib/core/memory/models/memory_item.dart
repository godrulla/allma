import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'memory_item.g.dart';

/// Types of memory that can be stored
enum MemoryType {
  @JsonValue('conversation')
  conversation,
  @JsonValue('personal')
  personal,
  @JsonValue('preference')
  preference,
  @JsonValue('factual')
  factual,
  @JsonValue('emotional')
  emotional,
  @JsonValue('system')
  system,
}

/// Represents a single memory item stored for a companion
@JsonSerializable()
class MemoryItem extends Equatable {
  final String id;
  final String companionId;
  final String content;
  final MemoryType type;
  final double importance;
  final DateTime timestamp;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const MemoryItem({
    required this.id,
    required this.companionId,
    required this.content,
    required this.type,
    required this.importance,
    required this.timestamp,
    this.tags = const [],
    this.metadata = const {},
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) =>
      _$MemoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryItemToJson(this);

  /// Create a memory item for a conversation
  factory MemoryItem.conversation({
    required String id,
    required String companionId,
    required String content,
    required DateTime timestamp,
    double importance = 0.5,
    List<String> tags = const [],
  }) {
    return MemoryItem(
      id: id,
      companionId: companionId,
      content: content,
      type: MemoryType.conversation,
      importance: importance,
      timestamp: timestamp,
      tags: ['conversation', ...tags],
    );
  }

  /// Create a memory item for personal information
  factory MemoryItem.personal({
    required String id,
    required String companionId,
    required String content,
    required DateTime timestamp,
    double importance = 0.8,
    List<String> tags = const [],
  }) {
    return MemoryItem(
      id: id,
      companionId: companionId,
      content: content,
      type: MemoryType.personal,
      importance: importance,
      timestamp: timestamp,
      tags: ['personal', ...tags],
    );
  }

  /// Create a memory item for preferences
  factory MemoryItem.preference({
    required String id,
    required String companionId,
    required String content,
    required DateTime timestamp,
    double importance = 0.7,
    List<String> tags = const [],
  }) {
    return MemoryItem(
      id: id,
      companionId: companionId,
      content: content,
      type: MemoryType.preference,
      importance: importance,
      timestamp: timestamp,
      tags: ['preference', ...tags],
    );
  }

  /// Create a memory item for factual information
  factory MemoryItem.factual({
    required String id,
    required String companionId,
    required String content,
    required DateTime timestamp,
    double importance = 0.6,
    List<String> tags = const [],
  }) {
    return MemoryItem(
      id: id,
      companionId: companionId,
      content: content,
      type: MemoryType.factual,
      importance: importance,
      timestamp: timestamp,
      tags: ['factual', ...tags],
    );
  }

  /// Create a memory item for emotional content
  factory MemoryItem.emotional({
    required String id,
    required String companionId,
    required String content,
    required DateTime timestamp,
    double importance = 0.9,
    List<String> tags = const [],
  }) {
    return MemoryItem(
      id: id,
      companionId: companionId,
      content: content,
      type: MemoryType.emotional,
      importance: importance,
      timestamp: timestamp,
      tags: ['emotional', ...tags],
    );
  }

  /// Create a memory item for system events
  factory MemoryItem.system({
    required String id,
    required String companionId,
    required String content,
    required DateTime timestamp,
    double importance = 0.3,
    List<String> tags = const [],
  }) {
    return MemoryItem(
      id: id,
      companionId: companionId,
      content: content,
      type: MemoryType.system,
      importance: importance,
      timestamp: timestamp,
      tags: ['system', ...tags],
    );
  }

  /// Check if this memory is recent (within last 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(timestamp).inHours < 24;
  }

  /// Check if this memory is old (older than 30 days)
  bool get isOld {
    final now = DateTime.now();
    return now.difference(timestamp).inDays > 30;
  }

  /// Check if this memory is highly important
  bool get isHighlyImportant => importance >= 0.8;

  /// Check if this memory contains personal information
  bool get isPersonalInfo => type == MemoryType.personal || tags.contains('personal');

  /// Check if this memory is about preferences
  bool get isPreference => type == MemoryType.preference || tags.contains('preference');

  /// Check if this memory is emotional
  bool get isEmotional => type == MemoryType.emotional || tags.contains('emotional');

  /// Get a brief summary of the memory
  String get summary {
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  /// Create a copy with updated fields
  MemoryItem copyWith({
    String? id,
    String? companionId,
    String? content,
    MemoryType? type,
    double? importance,
    DateTime? timestamp,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      companionId: companionId ?? this.companionId,
      content: content ?? this.content,
      type: type ?? this.type,
      importance: importance ?? this.importance,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companionId,
        content,
        type,
        importance,
        timestamp,
        tags,
        metadata,
      ];

  @override
  String toString() {
    return 'MemoryItem(id: $id, type: $type, importance: $importance, content: ${summary})';
  }
}

/// Memory statistics for a companion
@JsonSerializable()
class MemoryStats extends Equatable {
  final int totalMemories;
  final int conversationMemories;
  final int personalMemories;
  final int preferenceMemories;
  final int factualMemories;
  final int emotionalMemories;
  final int systemMemories;
  final double averageImportance;
  final DateTime? oldestMemory;
  final DateTime? newestMemory;

  const MemoryStats({
    required this.totalMemories,
    required this.conversationMemories,
    required this.personalMemories,
    required this.preferenceMemories,
    required this.factualMemories,
    required this.emotionalMemories,
    required this.systemMemories,
    required this.averageImportance,
    this.oldestMemory,
    this.newestMemory,
  });

  factory MemoryStats.fromJson(Map<String, dynamic> json) =>
      _$MemoryStatsFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryStatsToJson(this);

  /// Create memory stats from a list of memories
  factory MemoryStats.fromMemories(List<MemoryItem> memories) {
    if (memories.isEmpty) {
      return const MemoryStats(
        totalMemories: 0,
        conversationMemories: 0,
        personalMemories: 0,
        preferenceMemories: 0,
        factualMemories: 0,
        emotionalMemories: 0,
        systemMemories: 0,
        averageImportance: 0.0,
      );
    }

    final byType = <MemoryType, int>{};
    double totalImportance = 0.0;
    DateTime? oldest, newest;

    for (final memory in memories) {
      byType[memory.type] = (byType[memory.type] ?? 0) + 1;
      totalImportance += memory.importance;

      if (oldest == null || memory.timestamp.isBefore(oldest)) {
        oldest = memory.timestamp;
      }
      if (newest == null || memory.timestamp.isAfter(newest)) {
        newest = memory.timestamp;
      }
    }

    return MemoryStats(
      totalMemories: memories.length,
      conversationMemories: byType[MemoryType.conversation] ?? 0,
      personalMemories: byType[MemoryType.personal] ?? 0,
      preferenceMemories: byType[MemoryType.preference] ?? 0,
      factualMemories: byType[MemoryType.factual] ?? 0,
      emotionalMemories: byType[MemoryType.emotional] ?? 0,
      systemMemories: byType[MemoryType.system] ?? 0,
      averageImportance: totalImportance / memories.length,
      oldestMemory: oldest,
      newestMemory: newest,
    );
  }

  /// Get memory type distribution as percentages
  Map<MemoryType, double> get typeDistribution {
    if (totalMemories == 0) return {};

    return {
      MemoryType.conversation: conversationMemories / totalMemories * 100,
      MemoryType.personal: personalMemories / totalMemories * 100,
      MemoryType.preference: preferenceMemories / totalMemories * 100,
      MemoryType.factual: factualMemories / totalMemories * 100,
      MemoryType.emotional: emotionalMemories / totalMemories * 100,
      MemoryType.system: systemMemories / totalMemories * 100,
    };
  }

  /// Get the memory span duration
  Duration? get memorySpan {
    if (oldestMemory == null || newestMemory == null) return null;
    return newestMemory!.difference(oldestMemory!);
  }

  @override
  List<Object?> get props => [
        totalMemories,
        conversationMemories,
        personalMemories,
        preferenceMemories,
        factualMemories,
        emotionalMemories,
        systemMemories,
        averageImportance,
        oldestMemory,
        newestMemory,
      ];
}