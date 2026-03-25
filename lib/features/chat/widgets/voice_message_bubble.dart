import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../shared/utils/constants.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioPath;
  final Duration duration;
  final bool isFromUser;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const VoiceMessageBubble({
    required this.audioPath,
    required this.duration,
    required this.isFromUser,
    required this.timestamp,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late AnimationController _playAnimationController;
  late AudioPlayer _audioPlayer;
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _playAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _currentPosition == Duration.zero;
        });
        
        if (_isPlaying) {
          _waveAnimationController.repeat();
          _playAnimationController.forward();
        } else {
          _waveAnimationController.stop();
          _playAnimationController.reverse();
        }
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _currentPosition = Duration.zero;
          _isPlaying = false;
        });
        _waveAnimationController.stop();
        _playAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _playAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.audioPath));
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  void _changePlaybackSpeed() {
    setState(() {
      _playbackSpeed = _playbackSpeed == 1.0 ? 1.5 : _playbackSpeed == 1.5 ? 2.0 : 1.0;
    });
    if (_isPlaying) {
      _audioPlayer.setPlaybackRate(_playbackSpeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.duration.inMilliseconds > 0 
        ? _currentPosition.inMilliseconds / widget.duration.inMilliseconds 
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: widget.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isFromUser) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                  minWidth: 200,
                ),
                decoration: BoxDecoration(
                  color: widget.isFromUser 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: _buildBorderRadius(widget.isFromUser),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Play/Pause button
                        GestureDetector(
                          onTap: _togglePlayback,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.isFromUser
                                  ? theme.colorScheme.onPrimary.withOpacity(0.2)
                                  : theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedBuilder(
                              animation: _playAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_playAnimationController.value * 0.1),
                                  child: Icon(
                                    _isLoading 
                                        ? Icons.more_horiz
                                        : _isPlaying 
                                            ? Icons.pause 
                                            : Icons.play_arrow,
                                    color: widget.isFromUser
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Waveform and progress
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Waveform visualization
                              SizedBox(
                                height: 30,
                                child: AnimatedBuilder(
                                  animation: _waveAnimationController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: WaveformPainter(
                                        progress: progress,
                                        isPlaying: _isPlaying,
                                        animationValue: _waveAnimationController.value,
                                        waveColor: widget.isFromUser
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.primary,
                                        backgroundColor: widget.isFromUser
                                            ? theme.colorScheme.onPrimary.withOpacity(0.3)
                                            : theme.colorScheme.primary.withOpacity(0.2),
                                      ),
                                      size: const Size(double.infinity, 30),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Duration and progress
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_currentPosition),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: widget.isFromUser
                                          ? theme.colorScheme.onPrimary.withOpacity(0.8)
                                          : theme.colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(widget.duration),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: widget.isFromUser
                                          ? theme.colorScheme.onPrimary.withOpacity(0.8)
                                          : theme.colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Speed control
                        GestureDetector(
                          onTap: _changePlaybackSpeed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.isFromUser
                                  ? theme.colorScheme.onPrimary.withOpacity(0.2)
                                  : theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_playbackSpeed}x',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.isFromUser
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Timestamp
                    Text(
                      _formatTime(widget.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.isFromUser 
                            ? theme.colorScheme.onPrimary.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isFromUser) ...[
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
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

class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final double animationValue;
  final Color waveColor;
  final Color backgroundColor;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.animationValue,
    required this.waveColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    // Generate waveform bars
    const barCount = 40;
    final barWidth = size.width / barCount;
    final progressPosition = size.width * progress;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth;
      
      // Generate pseudo-random heights for waveform effect
      final baseHeight = (sin(i * 0.5) * 0.3 + 0.7) * size.height;
      final animatedHeight = isPlaying
          ? baseHeight * (0.7 + 0.3 * sin(animationValue * 2 * pi + i * 0.3))
          : baseHeight * 0.8;

      final rect = Rect.fromLTWH(
        x + barWidth * 0.1,
        size.height - animatedHeight,
        barWidth * 0.8,
        animatedHeight,
      );

      // Draw background bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        backgroundPaint,
      );

      // Draw active part based on progress
      if (x < progressPosition) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          activePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.animationValue != animationValue;
  }
}