# Allma API Documentation

## Overview

This document covers the integration with Google's Gemini API and the internal API architecture for the Allma AI Companion app. The system uses Google's generative AI services for conversation, image generation, and text-to-speech capabilities.

## Google Gemini API Integration

### Authentication

```dart
class GeminiAuthConfig {
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1';
  static const String apiKeyHeader = 'x-goog-api-key';
  
  static Map<String, String> getHeaders(String apiKey) {
    return {
      'Content-Type': 'application/json',
      apiKeyHeader: apiKey,
    };
  }
}
```

### Models Available

#### Gemini 2.5 Flash (Primary)
- **Model ID**: `gemini-2.5-flash`
- **Context Window**: 1M tokens
- **Cost**: $0.30/M input tokens, $2.50/M output tokens
- **Use Case**: Standard conversations

#### Gemini 2.5 Pro (Advanced)
- **Model ID**: `gemini-2.5-pro`
- **Context Window**: 2M tokens
- **Cost**: Higher than Flash
- **Use Case**: Complex reasoning tasks

### API Endpoints

#### Generate Content

```http
POST /v1/models/{model}/generateContent
```

**Request Structure:**
```dart
class GenerateContentRequest {
  final List<Content> contents;
  final SystemInstruction? systemInstruction;
  final GenerationConfig? generationConfig;
  final List<SafetySetting>? safetySettings;
  
  Map<String, dynamic> toJson() {
    return {
      'contents': contents.map((c) => c.toJson()).toList(),
      if (systemInstruction != null) 'systemInstruction': systemInstruction!.toJson(),
      if (generationConfig != null) 'generationConfig': generationConfig!.toJson(),
      if (safetySettings != null) 'safetySettings': safetySettings!.map((s) => s.toJson()).toList(),
    };
  }
}
```

**Content Structure:**
```dart
class Content {
  final String role; // 'user' or 'model'
  final List<Part> parts;
  
  Content({required this.role, required this.parts});
  
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': parts.map((p) => p.toJson()).toList(),
    };
  }
}

class Part {
  final String? text;
  final InlineData? inlineData; // For images
  final FileData? fileData;     // For files
  
  Part.text(this.text) : inlineData = null, fileData = null;
  Part.image(this.inlineData) : text = null, fileData = null;
  
  Map<String, dynamic> toJson() {
    if (text != null) return {'text': text};
    if (inlineData != null) return {'inlineData': inlineData!.toJson()};
    if (fileData != null) return {'fileData': fileData!.toJson()};
    throw Exception('Part must have text, inlineData, or fileData');
  }
}
```

### Generation Configuration

```dart
class GenerationConfig {
  final int? maxOutputTokens;
  final double? temperature;
  final double? topP;
  final int? topK;
  final List<String>? stopSequences;
  final String? responseMimeType;
  
  GenerationConfig({
    this.maxOutputTokens = 1024,
    this.temperature = 0.8,
    this.topP = 0.95,
    this.topK = 40,
    this.stopSequences,
    this.responseMimeType = 'text/plain',
  });
  
  Map<String, dynamic> toJson() {
    return {
      if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'topP': topP,
      if (topK != null) 'topK': topK,
      if (stopSequences != null) 'stopSequences': stopSequences,
      if (responseMimeType != null) 'responseMimeType': responseMimeType,
    };
  }
}
```

### Safety Settings

```dart
enum HarmCategory {
  harassment,
  hateSpeech,
  sexuallyExplicit,
  dangerousContent,
}

enum HarmBlockThreshold {
  blockNone,
  blockLowAndAbove,
  blockMediumAndAbove,
  blockOnlyHigh,
}

class SafetySetting {
  final HarmCategory category;
  final HarmBlockThreshold threshold;
  
  SafetySetting({required this.category, required this.threshold});
  
  Map<String, dynamic> toJson() {
    return {
      'category': _categoryToString(category),
      'threshold': _thresholdToString(threshold),
    };
  }
}
```

## Gemini Service Implementation

### Core Service Class

```dart
class GeminiService {
  final Dio _dio;
  final String _apiKey;
  final String _model;
  
  GeminiService({
    required String apiKey,
    String model = 'gemini-2.5-flash',
  }) : _apiKey = apiKey, _model = model, _dio = Dio() {
    _dio.options.baseUrl = GeminiAuthConfig.baseUrl;
    _dio.options.headers = GeminiAuthConfig.getHeaders(_apiKey);
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  
  Future<String> generateResponse({
    required List<Message> conversationHistory,
    required String systemPrompt,
    GenerationConfig? config,
  }) async {
    try {
      final contents = _convertMessagesToContents(conversationHistory);
      final request = GenerateContentRequest(
        contents: contents,
        systemInstruction: SystemInstruction(parts: [Part.text(systemPrompt)]),
        generationConfig: config ?? _getDefaultConfig(),
        safetySettings: _getDefaultSafetySettings(),
      );
      
      final response = await _dio.post(
        '/models/$_model:generateContent',
        data: request.toJson(),
      );
      
      return _extractTextFromResponse(response.data);
    } on DioException catch (e) {
      throw GeminiException.fromDioException(e);
    }
  }
  
  Future<Stream<String>> generateStreamingResponse({
    required List<Message> conversationHistory,
    required String systemPrompt,
    GenerationConfig? config,
  }) async {
    final contents = _convertMessagesToContents(conversationHistory);
    final request = GenerateContentRequest(
      contents: contents,
      systemInstruction: SystemInstruction(parts: [Part.text(systemPrompt)]),
      generationConfig: config ?? _getDefaultConfig(),
    );
    
    return _dio.post(
      '/models/$_model:streamGenerateContent',
      data: request.toJson(),
      options: Options(responseType: ResponseType.stream),
    ).asStream().expand((response) {
      return _parseStreamingResponse(response.data);
    });
  }
}
```

### Context Caching

```dart
class ContextCacheManager {
  final Map<String, CachedContext> _cache = {};
  
  Future<String> generateWithCache({
    required String systemPrompt,
    required List<Message> messages,
    Duration cacheExpiry = const Duration(hours: 1),
  }) async {
    final contextHash = _generateContextHash(systemPrompt, messages.take(10).toList());
    
    if (_cache.containsKey(contextHash) && !_cache[contextHash]!.isExpired) {
      // Use cached context
      return await _geminiService.generateResponse(
        conversationHistory: messages,
        systemPrompt: _cache[contextHash]!.cachedPrompt,
      );
    }
    
    // Create new cached context
    final cachedPrompt = await _createCachedContext(systemPrompt, messages);
    _cache[contextHash] = CachedContext(
      prompt: cachedPrompt,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(cacheExpiry),
    );
    
    return await _geminiService.generateResponse(
      conversationHistory: messages,
      systemPrompt: cachedPrompt,
    );
  }
}
```

## Image Generation (Imagen 4 Fast)

### Service Implementation

```dart
class ImageGenerationService {
  final Dio _dio;
  final String _apiKey;
  
  Future<String> generateCompanionAvatar({
    required CompanionAppearance appearance,
    String style = 'photorealistic',
    String resolution = '1024x1024',
  }) async {
    final prompt = _buildAvatarPrompt(appearance, style);
    
    final response = await _dio.post(
      '/v1/images:generate',
      data: {
        'prompt': prompt,
        'model': 'imagen-4-fast',
        'aspectRatio': '1:1',
        'safety': 'strict',
        'style': style,
      },
    );
    
    return response.data['images'][0]['uri'];
  }
  
  String _buildAvatarPrompt(CompanionAppearance appearance, String style) {
    return '''
Create a ${style} portrait of ${appearance.toImagePrompt()}.
High quality, professional lighting, friendly expression,
suitable for a social media profile picture.
Safe for work, appropriate for all audiences.
''';
  }
}
```

## Text-to-Speech Integration

### Service Implementation

```dart
class TextToSpeechService {
  final Dio _dio;
  final String _apiKey;
  
  Future<Uint8List> synthesizeSpeech({
    required String text,
    String voiceName = 'en-US-Wavenet-A',
    String languageCode = 'en-US',
    double speakingRate = 1.0,
    double pitch = 0.0,
  }) async {
    final response = await _dio.post(
      'https://texttospeech.googleapis.com/v1/text:synthesize',
      data: {
        'input': {'text': text},
        'voice': {
          'languageCode': languageCode,
          'name': voiceName,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': speakingRate,
          'pitch': pitch,
        },
      },
    );
    
    final audioContent = response.data['audioContent'];
    return base64Decode(audioContent);
  }
}
```

## Error Handling

### Custom Exceptions

```dart
class GeminiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;
  
  GeminiException(this.message, {this.statusCode, this.errorType});
  
  factory GeminiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectTimeout:
        return GeminiException('Connection timeout', statusCode: 408);
      case DioExceptionType.receiveTimeout:
        return GeminiException('Receive timeout', statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['error']?['message'] ?? 'Unknown error';
        return GeminiException(message, statusCode: statusCode);
      default:
        return GeminiException('Network error: ${e.message}');
    }
  }
}
```

### Retry Logic

```dart
class RetryHandler {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) rethrow;
        
        if (e is GeminiException && e.statusCode == 429) {
          // Rate limited, wait longer
          await Future.delayed(delay * attempt * 2);
        } else {
          await Future.delayed(delay);
        }
      }
    }
    throw Exception('Max retries exceeded');
  }
}
```

## Rate Limiting

### Implementation

```dart
class RateLimiter {
  final int maxRequestsPerMinute;
  final Queue<DateTime> _requestTimes = Queue();
  
  RateLimiter({this.maxRequestsPerMinute = 60});
  
  Future<void> waitIfNeeded() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));
    
    // Remove old requests
    while (_requestTimes.isNotEmpty && _requestTimes.first.isBefore(oneMinuteAgo)) {
      _requestTimes.removeFirst();
    }
    
    if (_requestTimes.length >= maxRequestsPerMinute) {
      final oldestRequest = _requestTimes.first;
      final waitTime = oldestRequest.add(Duration(minutes: 1)).difference(now);
      if (waitTime.isNegative == false) {
        await Future.delayed(waitTime);
      }
    }
    
    _requestTimes.addLast(now);
  }
}
```

## Cost Optimization

### Token Counting

```dart
class TokenCounter {
  // Approximate token counting for Gemini
  static int estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters for English
    return (text.length / 4).ceil();
  }
  
  static int estimatePromptTokens({
    required String systemPrompt,
    required List<Message> messages,
  }) {
    int total = estimateTokens(systemPrompt);
    for (final message in messages) {
      total += estimateTokens(message.content);
    }
    return total;
  }
}
```

### Batch Processing

```dart
class BatchProcessor {
  final List<BatchRequest> _queue = [];
  Timer? _batchTimer;
  
  void addRequest(BatchRequest request) {
    _queue.add(request);
    _scheduleBatch();
  }
  
  void _scheduleBatch() {
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(seconds: 5), _processBatch);
  }
  
  Future<void> _processBatch() async {
    if (_queue.isEmpty) return;
    
    final batch = List<BatchRequest>.from(_queue);
    _queue.clear();
    
    // Process batch with 50% cost savings
    await _geminiService.processBatch(batch);
  }
}
```

## Testing & Mocking

### Mock Service

```dart
class MockGeminiService implements GeminiService {
  final Map<String, String> _responses = {
    'hello': 'Hello! How can I help you today?',
    'how are you': 'I\'m doing well, thank you for asking!',
  };
  
  @override
  Future<String> generateResponse({
    required List<Message> conversationHistory,
    required String systemPrompt,
    GenerationConfig? config,
  }) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    final lastMessage = conversationHistory.last.content.toLowerCase();
    return _responses[lastMessage] ?? 'I understand. Please tell me more.';
  }
}
```

This API documentation provides comprehensive coverage of the Gemini integration and internal API architecture for the Allma AI companion app, ensuring robust, cost-effective, and scalable AI capabilities.