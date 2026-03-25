import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/models/message.dart';
import '../../../shared/utils/constants.dart';
import 'chat_bubble.dart';

class ChatMessageList extends ConsumerStatefulWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final String companionId;

  const ChatMessageList({
    required this.messages,
    required this.scrollController,
    required this.companionId,
    super.key,
  });

  @override
  ConsumerState<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends ConsumerState<ChatMessageList> {
  @override
  void didUpdateWidget(ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Auto-scroll when new messages arrive
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        // Add some top padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
        
        // Messages list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final message = widget.messages[index];
              final previousMessage = index > 0 ? widget.messages[index - 1] : null;
              final nextMessage = index < widget.messages.length - 1 
                  ? widget.messages[index + 1] 
                  : null;

              return _buildMessageWithSpacing(
                message: message,
                previousMessage: previousMessage,
                nextMessage: nextMessage,
                index: index,
              );
            },
            childCount: widget.messages.length,
          ),
        ),
        
        // Add some bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            duration: 2000.ms,
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Start your conversation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          )
          .animate()
          .fadeIn(delay: 500.ms)
          .slideY(begin: 0.3),
          
          const SizedBox(height: 8),
          
          Text(
            'Send a message to begin chatting with your companion',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 700.ms)
          .slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildMessageWithSpacing({
    required Message message,
    Message? previousMessage,
    Message? nextMessage,
    required int index,
  }) {
    final isFirstMessage = previousMessage == null;
    final isLastMessage = nextMessage == null;
    final showTimestamp = _shouldShowTimestamp(message, previousMessage);
    final isGrouped = _isMessageGrouped(message, previousMessage, nextMessage);

    return Column(
      children: [
        // Time separator
        if (showTimestamp)
          _buildTimeSeparator(message.timestamp)
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 50))
              .slideY(begin: -0.2),

        // Message bubble
        Padding(
          padding: EdgeInsets.only(
            top: isGrouped ? 2 : 8,
            bottom: isLastMessage ? 8 : (isGrouped ? 2 : 8),
          ),
          child: ChatBubble(
            message: message,
            onTap: () => _onMessageTap(message),
            onLongPress: () => _onMessageLongPress(message),
          )
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: index * 100),
            duration: AppConstants.animationDuration,
          )
          .slideX(
            begin: message.role == MessageRole.user ? 0.3 : -0.3,
            duration: AppConstants.animationDuration,
            curve: Curves.easeOutQuart,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              thickness: 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              _formatTimestamp(timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(Message message, Message? previousMessage) {
    if (previousMessage == null) return true;
    
    final timeDifference = message.timestamp.difference(previousMessage.timestamp);
    return timeDifference.inMinutes > 5; // Show timestamp if > 5 minutes apart
  }

  bool _isMessageGrouped(Message message, Message? previousMessage, Message? nextMessage) {
    if (previousMessage == null) return false;
    
    // Group messages from same sender within 2 minutes
    final isSameSender = message.role == previousMessage.role;
    final timeDifference = message.timestamp.difference(previousMessage.timestamp);
    
    return isSameSender && timeDifference.inMinutes < 2;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      // Today - show time
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _onMessageTap(Message message) {
    // Handle message tap - could show message details
    // For now, do nothing
  }

  void _onMessageLongPress(Message message) {
    _showMessageMenu(message);
  }

  void _showMessageMenu(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MessageMenuBottomSheet(
        message: message,
        onCopy: () => _copyMessage(message),
        onRetry: message.role == MessageRole.user ? () => _retryMessage(message) : null,
      ),
    );
  }

  void _copyMessage(Message message) {
    // TODO: Implement copy to clipboard
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _retryMessage(Message message) {
    Navigator.of(context).pop();
    
    // TODO: Implement message retry
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying message...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _scrollToBottom() {
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: AppConstants.animationDuration,
        curve: Curves.easeOut,
      );
    }
  }
}

/// Message context menu bottom sheet
class _MessageMenuBottomSheet extends StatelessWidget {
  final Message message;
  final VoidCallback onCopy;
  final VoidCallback? onRetry;

  const _MessageMenuBottomSheet({
    required this.message,
    required this.onCopy,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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

          // Message preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content.length > 100 
                  ? '${message.content.substring(0, 100)}...'
                  : message.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: onCopy,
          ),

          if (onRetry != null)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry'),
              onTap: onRetry,
            ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Message Info'),
            onTap: () {
              Navigator.of(context).pop();
              _showMessageInfo(context, message);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    )
    .animate()
    .slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutQuart)
    .fadeIn(duration: 200.ms);
  }

  void _showMessageInfo(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Type', message.type.name),
            _InfoRow('Role', message.role.name),
            _InfoRow('Timestamp', message.timestamp.toString()),
            _InfoRow('ID', message.id),
            if (message.metadata.isNotEmpty)
              _InfoRow('Metadata', message.metadata.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}