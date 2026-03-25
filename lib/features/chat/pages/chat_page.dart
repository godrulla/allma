import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/companions/models/companion.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/companion_header.dart';
import '../widgets/typing_indicator.dart';
import '../../../core/companions/services/companion_service.dart';
import '../../../shared/utils/constants.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String companionId;

  const ChatPage({
    required this.companionId,
    super.key,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Initialize chat when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider(widget.companionId).notifier).initializeChat();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.companionId));
    final companionAsync = ref.watch(companionProvider(widget.companionId));

    return Scaffold(
      appBar: AppBar(
        title: companionAsync.when(
          data: (companion) => companion != null
              ? CompanionHeader(companion: companion)
              : const Text('Chat'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.when(
              data: (messages) => ChatMessageList(
                messages: messages,
                scrollController: _scrollController,
                companionId: widget.companionId,
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load messages',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(chatProvider(widget.companionId).notifier).initializeChat();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Typing indicator
          Consumer(
            builder: (context, ref, child) {
              final isTyping = ref.watch(chatTypingProvider(widget.companionId));
              if (!isTyping) return const SizedBox.shrink();
              
              return companionAsync.when(
                data: (companion) => companion != null
                    ? TypingIndicator(companionName: companion.name)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          // Input bar
          ChatInputBar(
            controller: _messageController,
            focusNode: _inputFocusNode,
            onSendMessage: (message) => _sendMessage(message),
            onSendVoiceMessage: (audioPath) => _sendVoiceMessage(audioPath),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final chatNotifier = ref.read(chatProvider(widget.companionId).notifier);
    final typingNotifier = ref.read(chatTypingProvider(widget.companionId).notifier);
    
    try {
      // Clear input immediately for better UX
      _messageController.clear();
      
      // Send message with typing callback
      await chatNotifier.sendMessage(
        message,
        onTypingChanged: (isTyping) => typingNotifier.setTyping(isTyping),
      );
      
      // Scroll to bottom after message is sent
      _scrollToBottom();
      
    } catch (e) {
      // Ensure typing indicator is hidden on error
      typingNotifier.setTyping(false);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _sendMessage(message),
            ),
          ),
        );
        
        // Restore message to input if send failed
        _messageController.text = message;
      }
    }
  }

  Future<void> _sendVoiceMessage(String audioPath) async {
    // TODO: Implement voice message sending
    // This will be implemented in later phases
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice messages coming soon!'),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppConstants.animationDuration,
        curve: Curves.easeOut,
      );
    }
  }

  void _showChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ChatMenuBottomSheet(
        companionId: widget.companionId,
      ),
    );
  }
}

/// Chat menu bottom sheet
class ChatMenuBottomSheet extends ConsumerWidget {
  final String companionId;

  const ChatMenuBottomSheet({
    required this.companionId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionAsync = ref.watch(companionProvider(companionId));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Companion info
          companionAsync.when(
            data: (companion) => companion != null
                ? ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.smart_toy,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(companion.name),
                    subtitle: Text('${companion.totalInteractions} conversations'),
                  )
                : const SizedBox.shrink(),
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Menu options
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Companion Details'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to companion details page
            },
          ),

          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('Memories'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to memories page
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Chat Settings'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to chat settings
            },
          ),

          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Clear Chat History',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () => _showClearHistoryConfirmation(context, ref),
          ),

          const SizedBox(height: 16),
        ],
      ),
    )
    .animate()
    .slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutQuart)
    .fadeIn(duration: 200.ms);
  }

  void _showClearHistoryConfirmation(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop(); // Close menu first

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(chatProvider(companionId).notifier).clearHistory();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history cleared'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Provider for individual companions
final companionProvider = FutureProvider.family<Companion?, String>((ref, companionId) async {
  final companionService = await ref.read(companionServiceProvider.future);
  return await companionService.getCompanion(companionId);
});