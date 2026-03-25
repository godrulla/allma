import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

import '../../shared/models/message.dart';
import '../../shared/utils/constants.dart';

class GeminiService {
  final Dio _dio;
  final Logger _logger;
  final String _apiKey;

  GeminiService._({
    required Dio dio,
    required Logger logger,
    required String apiKey,
  })  : _dio = dio,
        _logger = logger,
        _apiKey = apiKey;

  static Future<GeminiService> create() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      // For demo/testing purposes, use a placeholder key
      print('Warning: Using demo API key. Gemini features will not work.');
    }

    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.geminiBaseUrl,
      connectTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey ?? 'demo_key_for_testing',
      },
    ));

    // Add logging interceptor in debug mode
    if (AppConstants.isDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ));
    }

    final logger = Logger();

    return GeminiService._(
      dio: dio,
      logger: logger,
      apiKey: apiKey ?? 'demo_key_for_testing',
    );
  }

  Future<String> generateResponse({
    required List<Message> conversationHistory,
    required String systemPrompt,
    GenerationConfig? config,
  }) async {
    try {
      // Check if using demo key
      if (_apiKey == 'demo_key_for_testing') {
        _logger.w('Using demo API key, returning mock response');
        return "Hello! I'm Allma, your AI companion. I'd love to chat with you, but I need a proper Gemini API key to function. Please add your GEMINI_API_KEY to the .env file to enable AI conversations.";
      }

      _logger.i('Generating response for ${conversationHistory.length} messages');

      final contents = _convertMessagesToContents(conversationHistory);
      final request = GenerateContentRequest(
        contents: contents,
        systemInstruction: SystemInstruction(
          parts: [Part.text(systemPrompt)],
        ),
        generationConfig: config ?? GenerationConfig.defaultConfig(),
      );

      final response = await _dio.post(
        '/models/${AppConstants.geminiModel}:generateContent',
        data: request.toJson(),
      );

      final responseText = _extractTextFromResponse(response.data);
      _logger.i('Response generated successfully');
      return responseText;
    } on DioException catch (e) {
      _logger.e('Gemini API error: ${e.message}');
      return "I'm having trouble connecting to my AI service right now. Please check your internet connection and API key configuration.";
    } catch (e) {
      _logger.e('Unexpected error: $e');
      return "Sorry, I encountered an error. Please try again later.";
    }
  }

  Future<Stream<String>> generateStreamingResponse({
    required List<Message> conversationHistory,
    required String systemPrompt,
    GenerationConfig? config,
  }) async {
    try {
      final contents = _convertMessagesToContents(conversationHistory);
      final request = GenerateContentRequest(
        contents: contents,
        systemInstruction: SystemInstruction(
          parts: [Part.text(systemPrompt)],
        ),
        generationConfig: config ?? GenerationConfig.defaultConfig(),
      );

      final response = await _dio.post(
        '/models/${AppConstants.geminiModel}:streamGenerateContent',
        data: request.toJson(),
        options: Options(responseType: ResponseType.stream),
      );

      return _parseStreamingResponse(response.data);
    } on DioException catch (e) {
      _logger.e('Streaming API error: ${e.message}');
      throw GeminiException.fromDioException(e);
    }
  }

  List<Content> _convertMessagesToContents(List<Message> messages) {
    return messages.map((message) {
      final role = message.role == MessageRole.user ? 'user' : 'model';
      return Content(
        role: role,
        parts: [Part.text(message.content)],
      );
    }).toList();
  }

  String _extractTextFromResponse(Map<String, dynamic> responseData) {
    final candidates = responseData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('No candidates in response');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    if (content == null) {
      throw GeminiException('No content in candidate');
    }

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw GeminiException('No parts in content');
    }

    final part = parts.first as Map<String, dynamic>;
    final text = part['text'] as String?;
    if (text == null) {
      throw GeminiException('No text in part');
    }

    return text;
  }

  /// Generate image using Imagen 4 Fast API
  Future<ImageGenerationResult> generateImage({
    required String prompt,
    ImageSize size = ImageSize.medium,
    ImageStyle style = ImageStyle.natural,
    int aspectRatio = 1, // 1 = square, 2 = landscape, 3 = portrait
    bool includeText = false,
  }) async {
    try {
      // Check if using demo key
      if (_apiKey == 'demo_key_for_testing') {
        _logger.w('Using demo API key, returning mock image response');
        return ImageGenerationResult.failure(
          "Image generation requires a proper Gemini API key. Please add your GEMINI_API_KEY to the .env file.",
          ImageGenerationError.configurationError,
        );
      }

      _logger.i('Generating image with prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');

      // Build enhanced prompt with style and safety filters
      final enhancedPrompt = _buildImagePrompt(prompt, style, includeText);

      final request = ImageGenerationRequest(
        prompt: enhancedPrompt,
        model: 'imagen-3.0-generate-001', // Imagen 4 Fast
        aspectRatio: _getAspectRatio(aspectRatio),
        negativePrompt: _getSafetyNegativePrompt(),
        safetySettings: _getImageSafetySettings(),
      );

      final response = await _dio.post(
        '/models/imagen-3.0-generate-001:generateImages',
        data: request.toJson(),
        options: Options(
          receiveTimeout: Duration(seconds: 60), // Image generation takes longer
        ),
      );

      final imageData = _extractImageFromResponse(response.data);
      _logger.i('Image generated successfully');
      
      return ImageGenerationResult.success(imageData);
      
    } on DioException catch (e) {
      _logger.e('Image generation API error: ${e.message}');
      return ImageGenerationResult.failure(
        "Failed to generate image. Please check your API configuration and try again.",
        ImageGenerationError.generationFailed,
      );
    } catch (e) {
      _logger.e('Unexpected error during image generation: $e');
      return ImageGenerationResult.failure(
        "Sorry, I encountered an error generating the image. Please try again.",
        ImageGenerationError.generationFailed,
      );
    }
  }

  /// Generate avatar image for companion
  Future<ImageGenerationResult> generateAvatar({
    required String companionName,
    required String personalityDescription,
    required String appearanceDescription,
    AvatarStyle style = AvatarStyle.realistic,
  }) async {
    try {
      final prompt = _buildAvatarPrompt(
        companionName: companionName,
        personality: personalityDescription,
        appearance: appearanceDescription,
        style: style,
      );

      return await generateImage(
        prompt: prompt,
        size: ImageSize.medium,
        style: style == AvatarStyle.realistic ? ImageStyle.photographic : ImageStyle.artistic,
        aspectRatio: 1, // Square for avatars
        includeText: false,
      );
      
    } catch (e) {
      _logger.e('Avatar generation error: $e');
      return ImageGenerationResult.failure(
        "Failed to generate avatar. Please try again.",
        ImageGenerationError.generationFailed,
      );
    }
  }

  /// Generate scene/background image
  Future<ImageGenerationResult> generateScene({
    required String sceneDescription,
    String? mood,
    String? timeOfDay,
    String? weatherCondition,
  }) async {
    try {
      final prompt = _buildScenePrompt(
        scene: sceneDescription,
        mood: mood,
        timeOfDay: timeOfDay,
        weather: weatherCondition,
      );

      return await generateImage(
        prompt: prompt,
        size: ImageSize.large,
        style: ImageStyle.cinematic,
        aspectRatio: 2, // Landscape for scenes
        includeText: false,
      );
      
    } catch (e) {
      _logger.e('Scene generation error: $e');
      return ImageGenerationResult.failure(
        "Failed to generate scene. Please try again.",
        ImageGenerationError.generationFailed,
      );
    }
  }

  /// Private helper methods for image generation
  String _buildImagePrompt(String userPrompt, ImageStyle style, bool includeText) {
    final styleDescriptor = _getStyleDescriptor(style);
    final textConstraint = includeText ? "" : ", no text, no words, no letters";
    
    return "Create a high-quality $styleDescriptor image: $userPrompt. "
           "Professional composition, good lighting, detailed$textConstraint.";
  }

  String _buildAvatarPrompt({
    required String companionName,
    required String personality,
    required String appearance,
    required AvatarStyle style,
  }) {
    final styleDescriptor = style == AvatarStyle.realistic 
        ? "photorealistic portrait"
        : style == AvatarStyle.anime 
            ? "anime-style character portrait"
            : "artistic character illustration";

    return "Create a $styleDescriptor of $companionName, an AI companion. "
           "Personality: $personality. "
           "Appearance: $appearance. "
           "Friendly expression, professional headshot style, clean background, "
           "high quality, detailed features, no text.";
  }

  String _buildScenePrompt({
    required String scene,
    String? mood,
    String? timeOfDay,
    String? weather,
  }) {
    final moodDesc = mood != null ? ", $mood mood" : "";
    final timeDesc = timeOfDay != null ? ", $timeOfDay lighting" : "";
    final weatherDesc = weather != null ? ", $weather weather" : "";
    
    return "Create a cinematic landscape scene: $scene$moodDesc$timeDesc$weatherDesc. "
           "High quality, detailed, professional composition, no text.";
  }

  String _getStyleDescriptor(ImageStyle style) {
    switch (style) {
      case ImageStyle.natural:
        return "natural and realistic";
      case ImageStyle.photographic:
        return "photographic";
      case ImageStyle.artistic:
        return "artistic and stylized";
      case ImageStyle.cinematic:
        return "cinematic and dramatic";
      case ImageStyle.anime:
        return "anime-style";
    }
  }

  String _getAspectRatio(int ratio) {
    switch (ratio) {
      case 1: return "1:1";    // Square
      case 2: return "16:9";   // Landscape
      case 3: return "9:16";   // Portrait
      default: return "1:1";
    }
  }

  String _getSafetyNegativePrompt() {
    return "violence, gore, explicit content, inappropriate content, "
           "harmful imagery, disturbing content, offensive material";
  }

  Map<String, dynamic> _getImageSafetySettings() {
    return {
      'harassment': 'BLOCK_MEDIUM_AND_ABOVE',
      'hate_speech': 'BLOCK_MEDIUM_AND_ABOVE',
      'sexually_explicit': 'BLOCK_MEDIUM_AND_ABOVE',
      'dangerous_content': 'BLOCK_MEDIUM_AND_ABOVE',
    };
  }

  GeneratedImageData _extractImageFromResponse(Map<String, dynamic> responseData) {
    final candidates = responseData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('No image candidates in response');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    
    // Extract image data (format depends on actual API response)
    final imageData = candidate['image'] as Map<String, dynamic>?;
    if (imageData == null) {
      throw GeminiException('No image data in candidate');
    }

    // Handle base64 encoded image
    final base64Data = imageData['bytesBase64Encoded'] as String?;
    if (base64Data != null) {
      final bytes = base64Decode(base64Data);
      return GeneratedImageData(
        bytes: bytes,
        format: imageData['mimeType'] as String? ?? 'image/png',
        width: imageData['width'] as int? ?? 1024,
        height: imageData['height'] as int? ?? 1024,
      );
    }

    // Handle URL-based response
    final imageUrl = imageData['uri'] as String?;
    if (imageUrl != null) {
      return GeneratedImageData(
        url: imageUrl,
        format: imageData['mimeType'] as String? ?? 'image/png',
        width: imageData['width'] as int? ?? 1024,
        height: imageData['height'] as int? ?? 1024,
      );
    }

    throw GeminiException('Invalid image data format');
  }

  Stream<String> _parseStreamingResponse(Stream<List<int>> responseStream) {
    return responseStream.map((bytes) {
      // Parse streaming JSON response
      // Implementation depends on Gemini's streaming format
      final jsonStr = String.fromCharCodes(bytes);
      // Parse and extract text chunks
      return jsonStr; // Simplified for now
    });
  }
}

class GenerateContentRequest {
  final List<Content> contents;
  final SystemInstruction? systemInstruction;
  final GenerationConfig? generationConfig;

  GenerateContentRequest({
    required this.contents,
    this.systemInstruction,
    this.generationConfig,
  });

  Map<String, dynamic> toJson() {
    return {
      'contents': contents.map((c) => c.toJson()).toList(),
      if (systemInstruction != null)
        'systemInstruction': systemInstruction!.toJson(),
      if (generationConfig != null)
        'generationConfig': generationConfig!.toJson(),
    };
  }
}

class Content {
  final String role;
  final List<Part> parts;

  Content({
    required this.role,
    required this.parts,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': parts.map((p) => p.toJson()).toList(),
    };
  }
}

class Part {
  final String? text;

  Part.text(this.text);

  Map<String, dynamic> toJson() {
    return {
      if (text != null) 'text': text,
    };
  }
}

class SystemInstruction {
  final List<Part> parts;

  SystemInstruction({required this.parts});

  Map<String, dynamic> toJson() {
    return {
      'parts': parts.map((p) => p.toJson()).toList(),
    };
  }
}

class GenerationConfig {
  final int? maxOutputTokens;
  final double? temperature;
  final double? topP;
  final int? topK;

  GenerationConfig({
    this.maxOutputTokens,
    this.temperature,
    this.topP,
    this.topK,
  });

  factory GenerationConfig.defaultConfig() {
    return GenerationConfig(
      maxOutputTokens: 1024,
      temperature: 0.8,
      topP: 0.95,
      topK: 40,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'topP': topP,
      if (topK != null) 'topK': topK,
    };
  }
}

class GeminiException implements Exception {
  final String message;
  final int? statusCode;

  GeminiException(this.message, {this.statusCode});

  factory GeminiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return GeminiException('Connection timeout', statusCode: 408);
      case DioExceptionType.receiveTimeout:
        return GeminiException('Response timeout', statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['error']?['message'] ??
            'HTTP error $statusCode';
        return GeminiException(message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return GeminiException('Request cancelled');
      default:
        return GeminiException('Network error: ${e.message}');
    }
  }

  @override
  String toString() => 'GeminiException: $message';
}

/// Image generation request model
class ImageGenerationRequest {
  final String prompt;
  final String model;
  final String aspectRatio;
  final String? negativePrompt;
  final Map<String, dynamic>? safetySettings;

  ImageGenerationRequest({
    required this.prompt,
    required this.model,
    required this.aspectRatio,
    this.negativePrompt,
    this.safetySettings,
  });

  Map<String, dynamic> toJson() {
    return {
      'instances': [
        {
          'prompt': prompt,
          if (negativePrompt != null) 'negative_prompt': negativePrompt,
        }
      ],
      'parameters': {
        'aspect_ratio': aspectRatio,
        if (safetySettings != null) ...safetySettings!,
        'output_options': {
          'compressed_output_type': 'JPEG',
        }
      }
    };
  }
}

/// Result class for image generation operations
class ImageGenerationResult {
  final bool isSuccess;
  final GeneratedImageData? data;
  final String? errorMessage;
  final ImageGenerationError? errorType;

  const ImageGenerationResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.errorType,
  });

  factory ImageGenerationResult.success(GeneratedImageData data) {
    return ImageGenerationResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory ImageGenerationResult.failure(String errorMessage, ImageGenerationError errorType) {
    return ImageGenerationResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ImageGenerationResult.success(data: $data)';
    } else {
      return 'ImageGenerationResult.failure(error: $errorMessage, type: $errorType)';
    }
  }
}

/// Generated image data model
class GeneratedImageData {
  final Uint8List? bytes;
  final String? url;
  final String format;
  final int width;
  final int height;

  GeneratedImageData({
    this.bytes,
    this.url,
    required this.format,
    required this.width,
    required this.height,
  }) : assert(bytes != null || url != null, 'Either bytes or url must be provided');

  bool get isLocal => bytes != null;
  bool get isRemote => url != null;

  @override
  String toString() {
    final dataType = isLocal ? 'local bytes' : 'remote URL';
    return 'GeneratedImageData($dataType, ${width}x$height, $format)';
  }
}

/// Image generation error types
enum ImageGenerationError {
  configurationError,
  generationFailed,
  invalidPrompt,
  networkError,
  rateLimitExceeded,
  safetyViolation,
}

/// Extension to get human-readable error messages
extension ImageGenerationErrorExt on ImageGenerationError {
  String get message {
    switch (this) {
      case ImageGenerationError.configurationError:
        return 'Image generation is not properly configured';
      case ImageGenerationError.generationFailed:
        return 'Failed to generate image. Please try again';
      case ImageGenerationError.invalidPrompt:
        return 'Invalid or inappropriate prompt';
      case ImageGenerationError.networkError:
        return 'Network error during image generation';
      case ImageGenerationError.rateLimitExceeded:
        return 'Rate limit exceeded. Please try again later';
      case ImageGenerationError.safetyViolation:
        return 'Prompt violates safety guidelines. Please try a different description';
    }
  }
}

/// Image size options
enum ImageSize {
  small,   // 512x512
  medium,  // 1024x1024
  large,   // 1536x1536
}

/// Image style options
enum ImageStyle {
  natural,
  photographic,
  artistic,
  cinematic,
  anime,
}

/// Avatar style options
enum AvatarStyle {
  realistic,
  artistic,
  anime,
}