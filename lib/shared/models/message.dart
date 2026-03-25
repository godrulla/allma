import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'message.g.dart';

@JsonSerializable()
class Message extends Equatable {
  final String id;
  final String content;
  final MessageType type;
  final MessageRole role;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.role,
    required this.timestamp,
    this.metadata = const {},
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  factory Message.user({
    required String id,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic> metadata = const {},
  }) {
    return Message(
      id: id,
      content: content,
      type: type,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory Message.companion({
    required String id,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic> metadata = const {},
  }) {
    return Message(
      id: id,
      content: content,
      type: type,
      role: MessageRole.companion,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [id, content, type, role, timestamp, metadata];
}

enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
  @JsonValue('system')
  system,
}

enum MessageRole {
  @JsonValue('user')
  user,
  @JsonValue('companion')
  companion,
  @JsonValue('system')
  system,
}