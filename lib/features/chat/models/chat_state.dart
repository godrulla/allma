import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

import '../../../shared/models/message.dart';

part 'chat_state.g.dart';

/// Represents the state of a chat conversation
@JsonSerializable()
class ChatState extends Equatable {
  final String companionId;
  final List<Message> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;
  final DateTime lastUpdated;
  final ChatMetadata metadata;

  const ChatState({
    required this.companionId,
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
    required this.lastUpdated,
    this.metadata = const ChatMetadata(),
  });

  factory ChatState.fromJson(Map<String, dynamic> json) =>
      _$ChatStateFromJson(json);

  Map<String, dynamic> toJson() => _$ChatStateToJson(this);

  /// Create initial state for a new chat
  factory ChatState.initial(String companionId) {
    return ChatState(
      companionId: companionId,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create loading state
  ChatState loading() {
    return copyWith(
      isLoading: true,
      error: null,
    );
  }

  /// Create error state
  ChatState withError(String error) {
    return copyWith(
      isLoading: false,
      error: error,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add a message to the conversation
  ChatState addMessage(Message message) {
    return copyWith(
      messages: [...messages, message],
      isLoading: false,
      error: null,
      lastUpdated: DateTime.now(),
      metadata: metadata.copyWith(
        totalMessages: messages.length + 1,
        lastMessageAt: message.timestamp,
      ),
    );
  }

  /// Add multiple messages
  ChatState addMessages(List<Message> newMessages) {
    return copyWith(
      messages: [...messages, ...newMessages],
      isLoading: false,
      error: null,
      lastUpdated: DateTime.now(),
      metadata: metadata.copyWith(
        totalMessages: messages.length + newMessages.length,
        lastMessageAt: newMessages.isNotEmpty ? newMessages.last.timestamp : metadata.lastMessageAt,
      ),
    );
  }

  /// Update typing state
  ChatState withTyping(bool isTyping) {
    return copyWith(
      isTyping: isTyping,
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear all messages
  ChatState clearMessages() {
    return copyWith(
      messages: [],
      error: null,
      lastUpdated: DateTime.now(),
      metadata: const ChatMetadata(),
    );
  }

  /// Get the last message
  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get user messages only
  List<Message> get userMessages => 
      messages.where((m) => m.role == MessageRole.user).toList();

  /// Get companion messages only
  List<Message> get companionMessages => 
      messages.where((m) => m.role == MessageRole.companion).toList();

  /// Check if conversation has started
  bool get hasMessages => messages.isNotEmpty;

  /// Check if the last message was from user
  bool get waitingForResponse => 
      lastMessage?.role == MessageRole.user;

  ChatState copyWith({
    String? companionId,
    List<Message>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
    DateTime? lastUpdated,
    ChatMetadata? metadata,
  }) {
    return ChatState(
      companionId: companionId ?? this.companionId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        companionId,
        messages,
        isLoading,
        isTyping,
        error,
        lastUpdated,
        metadata,
      ];
}

/// Metadata about the chat conversation
@JsonSerializable()
class ChatMetadata extends Equatable {
  final int totalMessages;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;
  final Duration? averageResponseTime;
  final Map<String, dynamic> customData;

  const ChatMetadata({
    this.totalMessages = 0,
    this.firstMessageAt,
    this.lastMessageAt,
    this.averageResponseTime,
    this.customData = const {},
  });

  factory ChatMetadata.fromJson(Map<String, dynamic> json) =>
      _$ChatMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMetadataToJson(this);

  /// Get conversation duration
  Duration? get conversationDuration {
    if (firstMessageAt == null || lastMessageAt == null) return null;
    return lastMessageAt!.difference(firstMessageAt!);
  }

  /// Check if this is a new conversation
  bool get isNewConversation => totalMessages == 0;

  ChatMetadata copyWith({
    int? totalMessages,
    DateTime? firstMessageAt,
    DateTime? lastMessageAt,
    Duration? averageResponseTime,
    Map<String, dynamic>? customData,
  }) {
    return ChatMetadata(
      totalMessages: totalMessages ?? this.totalMessages,
      firstMessageAt: firstMessageAt ?? this.firstMessageAt ?? 
          (this.firstMessageAt == null && lastMessageAt != null ? lastMessageAt : this.firstMessageAt),
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      customData: customData ?? this.customData,
    );
  }

  @override
  List<Object?> get props => [
        totalMessages,
        firstMessageAt,
        lastMessageAt,
        averageResponseTime,
        customData,
      ];
}

/// Represents different states of message delivery
enum MessageStatus {
  @JsonValue('sending')
  sending,
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('read')
  read,
  @JsonValue('failed')
  failed,
}

/// Extended message with chat-specific properties
@JsonSerializable()
class ChatMessage extends Message {
  final MessageStatus status;
  final bool isRetrying;
  final int retryCount;

  const ChatMessage({
    required super.id,
    required super.content,
    required super.type,
    required super.role,
    required super.timestamp,
    super.metadata = const {},
    this.status = MessageStatus.sent,
    this.isRetrying = false,
    this.retryCount = 0,
  });

  factory ChatMessage.fromMessage(Message message, {
    MessageStatus status = MessageStatus.sent,
    bool isRetrying = false,
    int retryCount = 0,
  }) {
    return ChatMessage(
      id: message.id,
      content: message.content,
      type: message.type,
      role: message.role,
      timestamp: message.timestamp,
      metadata: message.metadata,
      status: status,
      isRetrying: isRetrying,
      retryCount: retryCount,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// Create a copy with updated status
  ChatMessage withStatus(MessageStatus status) {
    return ChatMessage(
      id: id,
      content: content,
      type: type,
      role: role,
      timestamp: timestamp,
      metadata: metadata,
      status: status,
      isRetrying: isRetrying,
      retryCount: retryCount,
    );
  }

  /// Create a copy with retry information
  ChatMessage withRetry({bool? isRetrying, int? retryCount}) {
    return ChatMessage(
      id: id,
      content: content,
      type: type,
      role: role,
      timestamp: timestamp,
      metadata: metadata,
      status: status,
      isRetrying: isRetrying ?? this.isRetrying,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Check if message failed to send
  bool get hasFailed => status == MessageStatus.failed;

  /// Check if message is being sent
  bool get isSending => status == MessageStatus.sending;

  /// Check if message can be retried
  bool get canRetry => hasFailed && retryCount < 3;

  @override
  List<Object?> get props => [
        ...super.props,
        status,
        isRetrying,
        retryCount,
      ];
}

/// Chat event for state management
abstract class ChatEvent extends Equatable {
  const ChatEvent();
}

class ChatInitialized extends ChatEvent {
  final String companionId;

  const ChatInitialized(this.companionId);

  @override
  List<Object> get props => [companionId];
}

class MessageSent extends ChatEvent {
  final Message message;

  const MessageSent(this.message);

  @override
  List<Object> get props => [message];
}

class MessageReceived extends ChatEvent {
  final Message message;

  const MessageReceived(this.message);

  @override
  List<Object> get props => [message];
}

class TypingStarted extends ChatEvent {
  const TypingStarted();

  @override
  List<Object> get props => [];
}

class TypingStopped extends ChatEvent {
  const TypingStopped();

  @override
  List<Object> get props => [];
}

class ChatError extends ChatEvent {
  final String error;

  const ChatError(this.error);

  @override
  List<Object> get props => [error];
}

class ChatCleared extends ChatEvent {
  const ChatCleared();

  @override
  List<Object> get props => [];
}