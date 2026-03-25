import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/utils/constants.dart';
import '../../../core/audio/voice_recording_service_mock.dart'; // Using mock until record package is fixed
import '../../../core/audio/speech_recognition_service.dart';
import '../../../shared/widgets/multimedia_viewer.dart';
import 'image_generation_modal.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSendMessage;
  final Function(String)? onSendVoiceMessage;
  final Function(String, String?)? onSendImageMessage;
  final bool isEnabled;
  final String hintText;
  final int maxLines;

  const ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSendMessage,
    this.onSendVoiceMessage,
    this.onSendImageMessage,
    this.isEnabled = true,
    this.hintText = 'Type a message...',
    this.maxLines = 5,
    super.key,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> with TickerProviderStateMixin {
  bool _hasText = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcribedText = '';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final VoiceRecordingService _recordingService = VoiceRecordingService.instance;
  final SpeechRecognitionService _speechService = SpeechRecognitionService.instance;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    
    // Initialize pulse animation for recording indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Initialize services
    _initializeServices();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Transcription preview when recording
            if (_isRecording && _transcribedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Transcribing...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _transcribedText,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
              .animate()
              .slideY(begin: -0.5, duration: 200.ms)
              .fadeIn(duration: 200.ms),
            
            // Main input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text input
                Expanded(
                  child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment button (future feature)
                    if (!_hasText)
                      IconButton(
                        icon: Icon(
                          Icons.attach_file,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: widget.isEnabled ? _onAttachmentPressed : null,
                        tooltip: 'Attach file (coming soon)',
                      ),
                    
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        enabled: widget.isEnabled,
                        maxLines: widget.maxLines,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: theme.textTheme.bodyLarge,
                        onSubmitted: _hasText ? (value) => _sendMessage() : null,
                      ),
                    ),
                    
                    // Emoji button (future feature)
                    if (!_hasText)
                      IconButton(
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: widget.isEnabled ? _onEmojiPressed : null,
                        tooltip: 'Emoji (coming soon)',
                      ),
                  ],
                ),
              ),
            ),
            
                const SizedBox(width: 8),
                
                // Send/Voice button
                _buildActionButton(theme),
              ],
            ),
          ],
        ),
      ),
    )
    .animate()
    .slideY(begin: 1, duration: AppConstants.animationDuration)
    .fadeIn(duration: AppConstants.animationDuration);
  }

  Widget _buildActionButton(ThemeData theme) {
    if (_hasText) {
      return _buildSendButton(theme);
    } else {
      return _buildVoiceButton(theme);
    }
  }

  Widget _buildSendButton(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.send,
          color: theme.colorScheme.onPrimary,
          size: 20,
        ),
        onPressed: widget.isEnabled ? _sendMessage : null,
        tooltip: 'Send message',
      ),
    )
    .animate()
    .scale(
      duration: 200.ms,
      curve: Curves.elasticOut,
    )
    .rotate(
      begin: -0.25,
      duration: 200.ms,
      curve: Curves.easeOut,
    );
  }

  Widget _buildVoiceButton(ThemeData theme) {
    Widget button = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _isRecording 
            ? theme.colorScheme.error
            : _isProcessing
                ? theme.colorScheme.secondary
                : theme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: _isRecording 
              ? theme.colorScheme.error
              : _isProcessing
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.primary,
          width: 2,
        ),
      ),
      child: IconButton(
        icon: _isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onSecondary,
                  ),
                ),
              )
            : Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording 
                    ? theme.colorScheme.onError
                    : theme.colorScheme.primary,
                size: 20,
              ),
        onPressed: widget.isEnabled && !_isProcessing ? _toggleVoiceRecording : null,
        tooltip: _isRecording 
            ? 'Stop recording' 
            : _isProcessing 
                ? 'Processing...' 
                : 'Record voice message',
      ),
    );

    // Add pulse animation when recording
    if (_isRecording) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: button,
      );
    }

    return button;
  }

  void _sendMessage() {
    if (!widget.isEnabled || !_hasText) return;
    
    final message = widget.controller.text.trim();
    if (message.isEmpty) return;
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Clear the input
    widget.controller.clear();
    
    // Send the message
    widget.onSendMessage(message);
    
    // Keep focus on input
    widget.focusNode.requestFocus();
  }

  Future<void> _initializeServices() async {
    try {
      await _recordingService.initialize();
      await _speechService.initialize();
    } catch (e) {
      // Handle initialization errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice features may not be available: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _toggleVoiceRecording() {
    if (!widget.isEnabled) return;
    
    if (_isRecording) {
      _stopVoiceRecording();
    } else {
      _startVoiceRecording();
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      // Check permissions
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        _showPermissionDialog();
        return;
      }

      setState(() {
        _isRecording = true;
        _isProcessing = false;
        _transcribedText = '';
      });

      // Start pulse animation
      _pulseController.repeat(reverse: true);

      // Start recording
      final recordResult = await _recordingService.startRecording();
      if (!recordResult.isSuccess) {
        await _handleRecordingError(recordResult.errorMessage ?? 'Recording failed');
        return;
      }

      // Start speech recognition for real-time transcription
      await _speechService.startListening(
        onPartialResult: (text) {
          setState(() {
            _transcribedText = text;
          });
        },
        onResult: (text) {
          setState(() {
            _transcribedText = text;
          });
        },
      );

    } catch (e) {
      await _handleRecordingError('Failed to start recording: $e');
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      if (!_isRecording) return;
      
      setState(() {
        _isProcessing = true;
      });
      
      // Stop pulse animation
      _pulseController.stop();
      
      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Stop speech recognition
      await _speechService.stopListening();
      
      // Stop recording
      final recordResult = await _recordingService.stopRecording();
      
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });

      if (recordResult.isSuccess && recordResult.data != null) {
        // If we have transcribed text, use it
        if (_transcribedText.trim().isNotEmpty) {
          widget.controller.text = _transcribedText;
          _sendMessage();
        } else {
          // Send voice message file
          if (widget.onSendVoiceMessage != null) {
            widget.onSendVoiceMessage!(recordResult.data!);
          }
        }
      } else {
        await _handleRecordingError(recordResult.errorMessage ?? 'Recording failed');
      }
      
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      await _handleRecordingError('Failed to stop recording: $e');
    }
  }

  Future<void> _handleRecordingError(String error) async {
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _transcribedText = '';
    });
    
    _pulseController.stop();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'Microphone permission is required to record voice messages. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _onAttachmentPressed() {
    _showAttachmentOptions();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
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
            
            // Attachment options
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildAttachmentOption(
                  icon: Icons.auto_awesome,
                  label: 'Generate\nImage',
                  color: Colors.purple,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openImageGeneration();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_camera,
                  label: 'Camera',
                  color: Colors.blue,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.green,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openImageGeneration() async {
    await context.showImageGenerationModal(
      onImageGenerated: (imagePath, caption) {
        if (widget.onSendImageMessage != null) {
          widget.onSendImageMessage!(imagePath, caption);
        }
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.of(context).pop(); // Close bottom sheet
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (widget.onSendImageMessage != null) {
          widget.onSendImageMessage!(pickedFile.path, null);
        }
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }


  void _onEmojiPressed() {
    // TODO: Implement emoji picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emoji picker coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Enhanced input bar with more features
class EnhancedChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSendMessage;
  final Function(String)? onSendVoiceMessage;
  final Function(String)? onSendImage;
  final bool isEnabled;
  final bool showTypingIndicator;
  final String? typingText;

  const EnhancedChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSendMessage,
    this.onSendVoiceMessage,
    this.onSendImage,
    this.isEnabled = true,
    this.showTypingIndicator = false,
    this.typingText,
    super.key,
  });

  @override
  State<EnhancedChatInputBar> createState() => _EnhancedChatInputBarState();
}

class _EnhancedChatInputBarState extends State<EnhancedChatInputBar> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Typing indicator
        if (widget.showTypingIndicator)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.typingText ?? 'AI is thinking...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: -0.5, duration: 200.ms),
        
        // Action buttons
        if (_showActions)
          _buildActionButtons(theme)
              .animate()
              .slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutQuart)
              .fadeIn(duration: 200.ms),
        
        // Main input bar
        ChatInputBar(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onSendMessage: widget.onSendMessage,
          onSendVoiceMessage: widget.onSendVoiceMessage,
          isEnabled: widget.isEnabled,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.photo_camera,
            label: 'Camera',
            color: Colors.blue,
            onPressed: () => _onCameraPressed(),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.green,
            onPressed: () => _onGalleryPressed(),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.attach_file,
            label: 'File',
            color: Colors.orange,
            onPressed: () => _onFilePressed(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _onCameraPressed() {
    // TODO: Implement camera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera coming soon!')),
    );
  }

  void _onGalleryPressed() {
    // TODO: Implement gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery coming soon!')),
    );
  }

  void _onFilePressed() {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker coming soon!')),
    );
  }
}