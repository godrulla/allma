import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/message.dart';
import '../../../core/companions/services/companion_service.dart';
import '../../../core/storage/conversation_storage.dart';
import '../../../core/storage/providers/storage_providers.dart';

/// Chat state notifier for managing conversations
class ChatNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final String companionId;
  final CompanionService? _companionService;
  final ConversationStorage _conversationStorage;
  final Uuid _uuid = const Uuid();

  ChatNotifier({
    required this.companionId,
    required CompanionService companionService,
    required ConversationStorage conversationStorage,
  })  : _companionService = companionService,
        _conversationStorage = conversationStorage,
        super(const AsyncValue.loading());

  /// Constructor for loading state
  ChatNotifier.loading({
    required this.companionId,
    required ConversationStorage conversationStorage,
  })  : _companionService = null,
        _conversationStorage = conversationStorage,
        super(const AsyncValue.loading());

  /// Constructor for error state
  ChatNotifier.error({
    required this.companionId,
    required ConversationStorage conversationStorage,
    required Object error,
  })  : _companionService = null,
        _conversationStorage = conversationStorage,
        super(AsyncValue.error(error, StackTrace.current));

  /// Initialize chat by loading conversation history
  Future<void> initializeChat() async {
    try {
      state = const AsyncValue.loading();
      
      // If companion service is not available, show error
      if (_companionService == null) {
        state = AsyncValue.error('AI service is not available. Please check your configuration.', StackTrace.current);
        return;
      }
      
      // Load conversation history from local storage
      final messages = await _conversationStorage.loadRecentMessages(companionId);
      
      // Add welcome message if this is a new conversation
      if (messages.isEmpty) {
        final companion = await _companionService!.getCompanion(companionId);
        if (companion != null) {
          final welcomeMessage = Message.companion(
            id: _uuid.v4(),
            content: _generateWelcomeMessage(companion.name),
            metadata: {'isWelcome': true},
          );
          messages.add(welcomeMessage);
          
          // Save welcome message to storage
          await _conversationStorage.saveMessage(welcomeMessage, companionId);
        }
      }
      
      state = AsyncValue.data(messages);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Send a user message and get companion response
  Future<void> sendMessage(String content, {Function(bool)? onTypingChanged}) async {
    if (content.trim().isEmpty) return;
    
    // If companion service is not available, show error message
    if (_companionService == null) {
      // Still add user message but respond with error
      final currentMessages = state.value ?? [];
      final userMessage = Message.user(
        id: _uuid.v4(),
        content: content.trim(),
      );
      await _conversationStorage.saveMessage(userMessage, companionId);
      
      final errorMessage = Message.companion(
        id: _uuid.v4(),
        content: "I'm sorry, but I'm not available right now. The AI service is not configured properly. Please check your settings and try again.",
      );
      await _conversationStorage.saveMessage(errorMessage, companionId);
      
      state = AsyncValue.data([...currentMessages, userMessage, errorMessage]);
      return;
    }
    
    try {
      final currentMessages = state.value ?? [];
      
      // Create user message
      final userMessage = Message.user(
        id: _uuid.v4(),
        content: content.trim(),
      );

      // Save user message to storage first
      await _conversationStorage.saveMessage(userMessage, companionId);

      // Add user message to state immediately
      state = AsyncValue.data([...currentMessages, userMessage]);

      // Show typing indicator
      onTypingChanged?.call(true);
      
      // Add realistic delay for typing indicator
      await Future.delayed(const Duration(milliseconds: 800));

      // Generate companion response
      final conversationHistory = [...currentMessages, userMessage];
      final response = await _companionService!.generateCompanionResponse(
        companionId: companionId,
        userMessage: content.trim(),
        conversationHistory: conversationHistory,
        userId: 'demo-user', // TODO: Get from auth service
      );

      // Create companion message
      final companionMessage = Message.companion(
        id: _uuid.v4(),
        content: response.response ?? 'Sorry, I had trouble responding.',
      );

      // Save companion message to storage
      await _conversationStorage.saveMessage(companionMessage, companionId);

      // Hide typing indicator
      onTypingChanged?.call(false);

      // Add companion response to state
      final updatedMessages = [...conversationHistory, companionMessage];
      state = AsyncValue.data(updatedMessages);
      
    } catch (e, stackTrace) {
      // Hide typing indicator on error
      onTypingChanged?.call(false);
      
      // Don't update state on error, keep user message visible
      // The UI will handle showing the error
      rethrow;
    }
  }

  /// Resend the last message (for retry functionality)
  Future<void> resendLastMessage() async {
    final messages = state.value;
    if (messages == null || messages.isEmpty) return;

    // Find the last user message
    final lastUserMessage = messages.lastWhere(
      (message) => message.role == MessageRole.user,
      orElse: () => throw Exception('No user message to resend'),
    );

    // Remove messages after the last user message
    final messagesToKeep = <Message>[];
    for (final message in messages) {
      messagesToKeep.add(message);
      if (message.id == lastUserMessage.id) break;
    }

    // Update state and resend
    state = AsyncValue.data(messagesToKeep);
    await sendMessage(lastUserMessage.content);
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    try {
      // Clear from storage
      await _conversationStorage.clearConversation(companionId);
      
      // Keep only welcome message if it exists
      final currentMessages = state.value ?? [];
      final welcomeMessages = currentMessages.where(
        (message) => message.metadata['isWelcome'] == true,
      ).toList();

      // If we have a welcome message, save it back to storage
      if (welcomeMessages.isNotEmpty) {
        for (final message in welcomeMessages) {
          await _conversationStorage.saveMessage(message, companionId);
        }
      }

      state = AsyncValue.data(welcomeMessages);
      
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Add a system message (for notifications, etc.)
  void addSystemMessage(String content) {
    final currentMessages = state.value ?? [];
    final systemMessage = Message(
      id: _uuid.v4(),
      content: content,
      type: MessageType.system,
      role: MessageRole.system,
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data([...currentMessages, systemMessage]);
  }

  /// Mark a message as read (for future read receipts)
  void markMessageAsRead(String messageId) {
    final messages = state.value;
    if (messages == null) return;

    final updatedMessages = messages.map((message) {
      if (message.id == messageId) {
        final updatedMetadata = Map<String, dynamic>.from(message.metadata);
        updatedMetadata['readAt'] = DateTime.now().toIso8601String();
        return Message(
          id: message.id,
          content: message.content,
          type: message.type,
          role: message.role,
          timestamp: message.timestamp,
          metadata: updatedMetadata,
        );
      }
      return message;
    }).toList();

    state = AsyncValue.data(updatedMessages);
  }

  /// Get conversation statistics
  ChatStatistics getStatistics() {
    final messages = state.value ?? [];
    
    final userMessages = messages.where((m) => m.role == MessageRole.user).length;
    final companionMessages = messages.where((m) => m.role == MessageRole.companion).length;
    final totalMessages = messages.length;
    
    DateTime? firstMessage;
    DateTime? lastMessage;
    
    if (messages.isNotEmpty) {
      // Filter out welcome messages for stats
      final nonWelcomeMessages = messages.where(
        (m) => m.metadata['isWelcome'] != true,
      ).toList();
      
      if (nonWelcomeMessages.isNotEmpty) {
        firstMessage = nonWelcomeMessages.first.timestamp;
        lastMessage = nonWelcomeMessages.last.timestamp;
      }
    }

    return ChatStatistics(
      totalMessages: totalMessages,
      userMessages: userMessages,
      companionMessages: companionMessages,
      firstMessageAt: firstMessage,
      lastMessageAt: lastMessage,
    );
  }

  /// Generate a personalized welcome message
  String _generateWelcomeMessage(String companionName) {
    final welcomeMessages = [
      "Hi there! I'm $companionName. I'm excited to chat with you!",
      "Hello! $companionName here. What's on your mind today?",
      "Hey! I'm $companionName, and I'm looking forward to our conversation.",
      "Hi! It's $companionName. How are you doing today?",
      "Hello there! $companionName at your service. What would you like to talk about?",
    ];
    
    // Use a simple deterministic selection based on companion name
    final index = companionName.hashCode.abs() % welcomeMessages.length;
    return welcomeMessages[index];
  }

  /// Set typing indicator state
  void _setTyping(bool isTyping) {
    // This will be handled by a separate provider
    // We'll implement this in the typing provider below
  }
}

/// Typing indicator state notifier
class TypingNotifier extends StateNotifier<bool> {
  TypingNotifier() : super(false);

  void setTyping(bool isTyping) {
    state = isTyping;
  }

  void startTyping() {
    state = true;
  }

  void stopTyping() {
    state = false;
  }
}

/// Chat statistics model
class ChatStatistics {
  final int totalMessages;
  final int userMessages;
  final int companionMessages;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;

  const ChatStatistics({
    required this.totalMessages,
    required this.userMessages,
    required this.companionMessages,
    this.firstMessageAt,
    this.lastMessageAt,
  });

  Duration? get conversationDuration {
    if (firstMessageAt == null || lastMessageAt == null) return null;
    return lastMessageAt!.difference(firstMessageAt!);
  }

  double get averageResponseTime {
    // TODO: Calculate based on message timestamps
    return 0.0;
  }
}

/// Family provider for chat state per companion
final chatProvider = StateNotifierProvider.family<ChatNotifier, AsyncValue<List<Message>>, String>(
  (ref, companionId) {
    final companionServiceAsync = ref.watch(companionServiceProvider);
    final conversationStorage = ref.read(conversationStorageProvider);
    
    return companionServiceAsync.when(
      data: (companionService) => ChatNotifier(
        companionId: companionId,
        companionService: companionService,
        conversationStorage: conversationStorage,
      ),
      loading: () => ChatNotifier.loading(
        companionId: companionId,
        conversationStorage: conversationStorage,
      ),
      error: (error, stack) => ChatNotifier.error(
        companionId: companionId,
        conversationStorage: conversationStorage,
        error: error,
      ),
    );
  },
);

/// Family provider for typing state per companion
final chatTypingProvider = StateNotifierProvider.family<TypingNotifier, bool, String>(
  (ref, companionId) => TypingNotifier(),
);

/// Provider for chat statistics
final chatStatisticsProvider = Provider.family<ChatStatistics, String>(
  (ref, companionId) {
    final chatNotifier = ref.read(chatProvider(companionId).notifier);
    return chatNotifier.getStatistics();
  },
);

/// Global provider to manage typing across all chats
final globalTypingProvider = StateNotifierProvider<TypingNotifier, bool>(
  (ref) => TypingNotifier(),
);

/// Extension to easily set typing state
extension ChatProviderExtension on WidgetRef {
  void setCompanionTyping(String companionId, bool isTyping) {
    read(chatTypingProvider(companionId).notifier).setTyping(isTyping);
  }
}