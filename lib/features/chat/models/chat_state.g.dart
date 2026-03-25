// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatState _$ChatStateFromJson(Map<String, dynamic> json) => ChatState(
      companionId: json['companionId'] as String,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isLoading: json['isLoading'] as bool? ?? false,
      isTyping: json['isTyping'] as bool? ?? false,
      error: json['error'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      metadata: json['metadata'] == null
          ? const ChatMetadata()
          : ChatMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatStateToJson(ChatState instance) => <String, dynamic>{
      'companionId': instance.companionId,
      'messages': instance.messages,
      'isLoading': instance.isLoading,
      'isTyping': instance.isTyping,
      'error': instance.error,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'metadata': instance.metadata,
    };

ChatMetadata _$ChatMetadataFromJson(Map<String, dynamic> json) => ChatMetadata(
      totalMessages: (json['totalMessages'] as num?)?.toInt() ?? 0,
      firstMessageAt: json['firstMessageAt'] == null
          ? null
          : DateTime.parse(json['firstMessageAt'] as String),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      averageResponseTime: json['averageResponseTime'] == null
          ? null
          : Duration(
              microseconds: (json['averageResponseTime'] as num).toInt()),
      customData: json['customData'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ChatMetadataToJson(ChatMetadata instance) =>
    <String, dynamic>{
      'totalMessages': instance.totalMessages,
      'firstMessageAt': instance.firstMessageAt?.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'averageResponseTime': instance.averageResponseTime?.inMicroseconds,
      'customData': instance.customData,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      status: $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
          MessageStatus.sent,
      isRetrying: json['isRetrying'] as bool? ?? false,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'metadata': instance.metadata,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'isRetrying': instance.isRetrying,
      'retryCount': instance.retryCount,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.audio: 'audio',
  MessageType.system: 'system',
};

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.companion: 'companion',
  MessageRole.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.read: 'read',
  MessageStatus.failed: 'failed',
};
