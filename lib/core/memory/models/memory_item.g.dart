// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryItem _$MemoryItemFromJson(Map<String, dynamic> json) => MemoryItem(
      id: json['id'] as String,
      companionId: json['companionId'] as String,
      content: json['content'] as String,
      type: $enumDecode(_$MemoryTypeEnumMap, json['type']),
      importance: (json['importance'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$MemoryItemToJson(MemoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'companionId': instance.companionId,
      'content': instance.content,
      'type': _$MemoryTypeEnumMap[instance.type]!,
      'importance': instance.importance,
      'timestamp': instance.timestamp.toIso8601String(),
      'tags': instance.tags,
      'metadata': instance.metadata,
    };

const _$MemoryTypeEnumMap = {
  MemoryType.conversation: 'conversation',
  MemoryType.personal: 'personal',
  MemoryType.preference: 'preference',
  MemoryType.factual: 'factual',
  MemoryType.emotional: 'emotional',
  MemoryType.system: 'system',
};

MemoryStats _$MemoryStatsFromJson(Map<String, dynamic> json) => MemoryStats(
      totalMemories: (json['totalMemories'] as num).toInt(),
      conversationMemories: (json['conversationMemories'] as num).toInt(),
      personalMemories: (json['personalMemories'] as num).toInt(),
      preferenceMemories: (json['preferenceMemories'] as num).toInt(),
      factualMemories: (json['factualMemories'] as num).toInt(),
      emotionalMemories: (json['emotionalMemories'] as num).toInt(),
      systemMemories: (json['systemMemories'] as num).toInt(),
      averageImportance: (json['averageImportance'] as num).toDouble(),
      oldestMemory: json['oldestMemory'] == null
          ? null
          : DateTime.parse(json['oldestMemory'] as String),
      newestMemory: json['newestMemory'] == null
          ? null
          : DateTime.parse(json['newestMemory'] as String),
    );

Map<String, dynamic> _$MemoryStatsToJson(MemoryStats instance) =>
    <String, dynamic>{
      'totalMemories': instance.totalMemories,
      'conversationMemories': instance.conversationMemories,
      'personalMemories': instance.personalMemories,
      'preferenceMemories': instance.preferenceMemories,
      'factualMemories': instance.factualMemories,
      'emotionalMemories': instance.emotionalMemories,
      'systemMemories': instance.systemMemories,
      'averageImportance': instance.averageImportance,
      'oldestMemory': instance.oldestMemory?.toIso8601String(),
      'newestMemory': instance.newestMemory?.toIso8601String(),
    };
