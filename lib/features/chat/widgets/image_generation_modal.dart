import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/gemini_service.dart';
import '../../../core/companions/services/companion_service.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';

class ImageGenerationModal extends ConsumerStatefulWidget {
  final Function(String imagePath, String? caption)? onImageGenerated;
  final String? initialPrompt;

  const ImageGenerationModal({
    this.onImageGenerated,
    this.initialPrompt,
    super.key,
  });

  @override
  ConsumerState<ImageGenerationModal> createState() => _ImageGenerationModalState();
}

class _ImageGenerationModalState extends ConsumerState<ImageGenerationModal>
    with TickerProviderStateMixin {
  late TextEditingController _promptController;
  late AnimationController _generateAnimationController;
  
  bool _isGenerating = false;
  String? _generatedImagePath;
  String? _errorMessage;
  ImageStyle _selectedStyle = ImageStyle.photographic;

  final List<ImageStyle> _imageStyles = [
    ImageStyle.photographic,
    ImageStyle.artistic,
    ImageStyle.anime,
    ImageStyle.cinematic,
    ImageStyle.natural,
  ];

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt ?? '');
    _generateAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _generateAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a description for the image';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImagePath = null;
    });

    _generateAnimationController.repeat();

    try {
      final geminiServiceAsync = await ref.read(geminiServiceProvider.future);
      final result = await geminiServiceAsync.generateImage(
        prompt: _promptController.text.trim(),
        style: _selectedStyle,
      );

      if (result.isSuccess && result.data != null) {
        setState(() {
          // Use URL if available, otherwise save bytes to temp file
          if (result.data!.url != null) {
            _generatedImagePath = result.data!.url;
          } else if (result.data!.bytes != null) {
            // For now, show error - we'd need to save bytes to file
            _errorMessage = 'Generated image needs to be saved to file';
          } else {
            _errorMessage = 'Failed to get image data';
          }
        });
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to generate image';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating image: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
      _generateAnimationController.stop();
      _generateAnimationController.reset();
    }
  }

  void _useImage() {
    if (_generatedImagePath != null) {
      widget.onImageGenerated?.call(_generatedImagePath!, _promptController.text);
      Navigator.of(context).pop();
    }
  }

  void _regenerate() {
    setState(() {
      _generatedImagePath = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Generate Image',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prompt input
                  Text(
                    'Describe the image you want to create',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'A cute robot companion sitting in a garden with flowers...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Style selection
                  Text(
                    'Choose a style',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageStyles.length,
                      itemBuilder: (context, index) {
                        final style = _imageStyles[index];
                        final isSelected = style == _selectedStyle;
                        
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _imageStyles.length - 1 ? 12 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedStyle = style),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : theme.colorScheme.surface,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getStyleIcon(style),
                                    size: 32,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getStyleName(style),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Generate button
                  PrimaryButton(
                    onPressed: _isGenerating ? null : _generateImage,
                    isLoading: _isGenerating,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isGenerating) ...[
                          const Icon(Icons.auto_awesome, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(_isGenerating ? 'Generating...' : 'Generate Image'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Generation status or result
                  if (_isGenerating)
                    _buildGeneratingStatus(theme)
                  else if (_errorMessage != null)
                    _buildErrorMessage(theme)
                  else if (_generatedImagePath != null)
                    _buildGeneratedImage(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildGeneratingStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _generateAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _generateAnimationController.value * 2 * 3.14159,
                child: Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Creating your image...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedImage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Generated image
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _generatedImagePath!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                onPressed: _regenerate,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Regenerate'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                onPressed: _useImage,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, size: 18),
                    SizedBox(width: 8),
                    Text('Send'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getStyleIcon(ImageStyle style) {
    switch (style) {
      case ImageStyle.photographic:
        return Icons.photo_camera;
      case ImageStyle.artistic:
        return Icons.palette;
      case ImageStyle.anime:
        return Icons.face;
      case ImageStyle.cinematic:
        return Icons.movie;
      case ImageStyle.natural:
        return Icons.nature;
    }
  }

  String _getStyleName(ImageStyle style) {
    switch (style) {
      case ImageStyle.photographic:
        return 'Photo';
      case ImageStyle.artistic:
        return 'Artistic';
      case ImageStyle.anime:
        return 'Anime';
      case ImageStyle.cinematic:
        return 'Cinematic';
      case ImageStyle.natural:
        return 'Natural';
    }
  }
}

// Extension to show the modal
extension ImageGenerationModalExtension on BuildContext {
  Future<void> showImageGenerationModal({
    Function(String imagePath, String? caption)? onImageGenerated,
    String? initialPrompt,
  }) {
    return showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageGenerationModal(
        onImageGenerated: onImageGenerated,
        initialPrompt: initialPrompt,
      ),
    );
  }
}