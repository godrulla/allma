import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

import '../../../shared/models/message.dart';
import '../../../shared/utils/constants.dart';
import 'voice_message_bubble.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isTyping;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatBubble({
    required this.message,
    this.isTyping = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    
    // Handle voice messages
    if (message.type == MessageType.audio) {
      return _buildVoiceMessage(context, isUser);
    }
    
    // Handle image messages
    if (message.type == MessageType.image) {
      return _buildImageMessage(context, isUser);
    }
    
    // Handle regular text messages
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isUser 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: _buildBorderRadius(isUser),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTyping)
                      _buildTypingIndicator(theme)
                    else
                      _buildMessageContent(context, isUser),
                    const SizedBox(height: 4),
                    _buildTimestamp(context, isUser),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, isUser: true),
          ],
        ],
      ),
    )
    .animate()
    .slideY(
      begin: 0.3,
      duration: AppConstants.animationDuration,
      curve: Curves.easeOutQuart,
    )
    .fadeIn(
      duration: AppConstants.animationDuration,
      curve: Curves.easeOut,
    );
  }

  Widget _buildAvatar(BuildContext context, {bool isUser = false}) {
    final theme = Theme.of(context);
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.secondary.withOpacity(0.1),
        border: Border.all(
          color: isUser 
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
          width: 2,
        ),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: isUser 
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
      ),
    );
  }

  BorderRadius _buildBorderRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(AppConstants.borderRadius),
      topRight: const Radius.circular(AppConstants.borderRadius),
      bottomLeft: Radius.circular(isUser ? AppConstants.borderRadius : 4),
      bottomRight: Radius.circular(isUser ? 4 : AppConstants.borderRadius),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    
    return Text(
      message.content,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isUser 
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        height: 1.4,
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    final timeString = _formatTime(message.timestamp);
    
    return Text(
      timeString,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isUser 
            ? theme.colorScheme.onPrimary.withOpacity(0.7)
            : theme.colorScheme.onSurface.withOpacity(0.5),
        fontSize: 10,
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Typing',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(3, (index) {
          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.2, 1.2),
            duration: const Duration(milliseconds: 600),
            delay: Duration(milliseconds: index * 200),
          );
        }),
      ],
    );
  }

  Widget _buildVoiceMessage(BuildContext context, bool isUser) {
    final audioPath = message.metadata['audioPath'] as String? ?? message.content;
    final durationMs = message.metadata['duration'] as int? ?? 0;
    final duration = Duration(milliseconds: durationMs);
    
    return VoiceMessageBubble(
      audioPath: audioPath,
      duration: duration,
      isFromUser: isUser,
      timestamp: message.timestamp,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
  
  Widget _buildImageMessage(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    final imagePath = message.metadata['imagePath'] as String? ?? message.content;
    final caption = message.metadata['caption'] as String?;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isUser 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: _buildBorderRadius(isUser),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppConstants.borderRadius),
                        topRight: const Radius.circular(AppConstants.borderRadius),
                        bottomLeft: caption != null ? Radius.zero : Radius.circular(isUser ? AppConstants.borderRadius : 4),
                        bottomRight: caption != null ? Radius.zero : Radius.circular(isUser ? 4 : AppConstants.borderRadius),
                      ),
                      child: _buildImageWidget(imagePath),
                    ),
                    // Caption and timestamp
                    if (caption != null || true) // Always show timestamp area
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (caption != null) ...[
                              Text(
                                caption,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isUser
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              _formatTime(message.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isUser 
                                    ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, isUser: true),
          ],
        ],
      ),
    )
    .animate()
    .slideY(
      begin: 0.3,
      duration: AppConstants.animationDuration,
      curve: Curves.easeOutQuart,
    )
    .fadeIn(
      duration: AppConstants.animationDuration,
      curve: Curves.easeOut,
    );
  }
  
  Widget _buildImageWidget(String imagePath) {
    // Check if it's a file path or URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    } else {
      // Local file
      final file = File(imagePath);
      return Image.file(
        file,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          );
        },
      );
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Animated typing indicator widget
class TypingBubble extends StatelessWidget {
  final String companionName;

  const TypingBubble({
    required this.companionName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary.withOpacity(0.1),
              border: Border.all(
                color: theme.colorScheme.secondary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadius),
                topRight: Radius.circular(AppConstants.borderRadius),
                bottomRight: Radius.circular(AppConstants.borderRadius),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$companionName is typing',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(3, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.2, 1.2),
                    duration: const Duration(milliseconds: 600),
                    delay: Duration(milliseconds: index * 200),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .slideY(
      begin: 0.3,
      duration: AppConstants.animationDuration,
      curve: Curves.easeOutQuart,
    )
    .fadeIn(
      duration: AppConstants.animationDuration,
      curve: Curves.easeOut,
    );
  }
}