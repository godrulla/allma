import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/constants.dart';

class MultimediaViewer extends StatefulWidget {
  final String mediaPath;
  final MultimediaType type;
  final String? caption;
  final List<String>? additionalMedia;
  final int initialIndex;

  const MultimediaViewer({
    required this.mediaPath,
    required this.type,
    this.caption,
    this.additionalMedia,
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<MultimediaViewer> createState() => _MultimediaViewerState();
}

class _MultimediaViewerState extends State<MultimediaViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TransformationController _transformationController;
  late AnimationController _overlayAnimationController;
  late AnimationController _scaleAnimationController;
  
  int _currentIndex = 0;
  bool _showOverlay = true;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _overlayAnimationController.forward();
    
    // Auto-hide overlay after 3 seconds
    _scheduleOverlayHide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    _overlayAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  void _scheduleOverlayHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showOverlay) {
        _toggleOverlay();
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
    
    if (_showOverlay) {
      _overlayAnimationController.forward();
      _scheduleOverlayHide();
    } else {
      _overlayAnimationController.reverse();
    }
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
      _scaleAnimationController.reverse();
    } else {
      final scale = 2.0;
      final matrix = Matrix4.identity()..scale(scale);
      _transformationController.value = matrix;
      _scaleAnimationController.forward();
    }
    setState(() {
      _isZoomed = !_isZoomed;
    });
  }

  Future<void> _shareMedia() async {
    try {
      final mediaPath = _getCurrentMediaPath();
      if (mediaPath.startsWith('http')) {
        await Share.share(mediaPath);
      } else {
        await Share.shareXFiles([XFile(mediaPath)]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  void _saveMedia() {
    // TODO: Implement save to gallery functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save functionality coming soon')),
    );
  }

  String _getCurrentMediaPath() {
    if (widget.additionalMedia != null && widget.additionalMedia!.isNotEmpty) {
      return widget.additionalMedia![_currentIndex];
    }
    return widget.mediaPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Media content
          GestureDetector(
            onTap: _toggleOverlay,
            onDoubleTap: widget.type == MultimediaType.image ? _handleDoubleTap : null,
            child: Center(
              child: widget.additionalMedia != null && widget.additionalMedia!.isNotEmpty
                  ? _buildPageView()
                  : _buildSingleMedia(),
            ),
          ),
          
          // Overlay controls
          AnimatedBuilder(
            animation: _overlayAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _overlayAnimationController.value,
                child: IgnorePointer(
                  ignoring: !_showOverlay,
                  child: child,
                ),
              );
            },
            child: _buildOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          _isZoomed = false;
        });
        _transformationController.value = Matrix4.identity();
        
        // Show overlay when changing pages
        if (!_showOverlay) {
          _toggleOverlay();
        }
      },
      itemCount: widget.additionalMedia!.length,
      itemBuilder: (context, index) {
        final mediaPath = widget.additionalMedia![index];
        return _buildMediaWidget(mediaPath);
      },
    );
  }

  Widget _buildSingleMedia() {
    return _buildMediaWidget(widget.mediaPath);
  }

  Widget _buildMediaWidget(String mediaPath) {
    switch (widget.type) {
      case MultimediaType.image:
        return _buildImageWidget(mediaPath);
      case MultimediaType.video:
        return _buildVideoWidget(mediaPath);
    }
  }

  Widget _buildImageWidget(String imagePath) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: imagePath.startsWith('http://') || imagePath.startsWith('https://')
          ? Image.network(
              imagePath,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              },
            )
          : Image.file(
              File(imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              },
            ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
  }

  Widget _buildVideoWidget(String videoPath) {
    // TODO: Implement video player
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            'Video player coming soon',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Top overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Page indicator
                  if (widget.additionalMedia != null && widget.additionalMedia!.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.additionalMedia!.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Share button
                      GestureDetector(
                        onTap: _shareMedia,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Save button
                      GestureDetector(
                        onTap: _saveMedia,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const Spacer(),
        
        // Bottom overlay with caption
        if (widget.caption != null && widget.caption!.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum MultimediaType {
  image,
  video,
}

// Extension to show the multimedia viewer
extension MultimediaViewerExtension on BuildContext {
  Future<void> showMultimediaViewer({
    required String mediaPath,
    required MultimediaType type,
    String? caption,
    List<String>? additionalMedia,
    int initialIndex = 0,
  }) {
    // Hide status bar for full screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    return Navigator.of(this)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MultimediaViewer(
              mediaPath: mediaPath,
              type: type,
              caption: caption,
              additionalMedia: additionalMedia,
              initialIndex: initialIndex,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        )
        .then((_) {
          // Restore status bar when returning
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        });
  }
}