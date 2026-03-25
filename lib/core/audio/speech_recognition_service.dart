import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

/// Service for handling speech-to-text conversion
class SpeechRecognitionService {
  static SpeechRecognitionService? _instance;
  static SpeechRecognitionService get instance => _instance ??= SpeechRecognitionService._();
  
  SpeechRecognitionService._();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Logger _logger = Logger();

  bool _isInitialized = false;
  bool _isListening = false;
  List<stt.LocaleName> _availableLocales = [];
  String _selectedLocaleId = 'en_US';

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get available locales
  List<stt.LocaleName> get availableLocales => _availableLocales;

  /// Get selected locale
  String get selectedLocaleId => _selectedLocaleId;

  /// Initialize speech recognition service
  Future<SpeechRecognitionResult> initialize() async {
    try {
      // Check microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        return SpeechRecognitionResult.failure(
          'Microphone permission is required for speech recognition',
          SpeechRecognitionError.permissionDenied,
        );
      }

      // Initialize speech to text
      final isAvailable = await _speechToText.initialize(
        onStatus: _onStatusChanged,
        onError: _onError,
        debugLogging: kDebugMode,
      );

      if (!isAvailable) {
        return SpeechRecognitionResult.failure(
          'Speech recognition not available on this device',
          SpeechRecognitionError.notSupported,
        );
      }

      // Get available locales
      _availableLocales = await _speechToText.locales();
      
      // Set default locale based on system locale or fallback to English
      _setDefaultLocale();

      _isInitialized = true;
      _logger.i('Speech recognition service initialized successfully');
      _logger.d('Available locales: ${_availableLocales.length}');
      
      return SpeechRecognitionResult.success();
      
    } catch (e) {
      _logger.e('Failed to initialize speech recognition: $e');
      return SpeechRecognitionResult.failure(
        'Failed to initialize speech recognition: $e',
        SpeechRecognitionError.initializationFailed,
      );
    }
  }

  /// Start listening for speech
  Future<SpeechRecognitionResult> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Duration? timeout,
  }) async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        if (!initResult.isSuccess) {
          return initResult;
        }
      }

      if (_isListening) {
        return SpeechRecognitionResult.failure(
          'Already listening',
          SpeechRecognitionError.alreadyListening,
        );
      }

      await _speechToText.listen(
        onResult: (result) => _onSpeechResult(result, onResult, onPartialResult),
        localeId: _selectedLocaleId,
        partialResults: true,
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      _isListening = true;
      _logger.i('Started listening for speech (locale: $_selectedLocaleId)');
      
      return SpeechRecognitionResult.success();
      
    } catch (e) {
      _logger.e('Failed to start listening: $e');
      return SpeechRecognitionResult.failure(
        'Failed to start speech recognition: $e',
        SpeechRecognitionError.listeningFailed,
      );
    }
  }

  /// Stop listening for speech
  Future<SpeechRecognitionResult> stopListening() async {
    try {
      if (!_isListening) {
        return SpeechRecognitionResult.failure(
          'Not currently listening',
          SpeechRecognitionError.notListening,
        );
      }

      await _speechToText.stop();
      _isListening = false;
      
      _logger.i('Stopped listening for speech');
      return SpeechRecognitionResult.success();
      
    } catch (e) {
      _logger.e('Failed to stop listening: $e');
      return SpeechRecognitionResult.failure(
        'Failed to stop speech recognition: $e',
        SpeechRecognitionError.listeningFailed,
      );
    }
  }

  /// Cancel current listening session
  Future<SpeechRecognitionResult> cancelListening() async {
    try {
      if (!_isListening) {
        return SpeechRecognitionResult.success(); // Already not listening
      }

      await _speechToText.cancel();
      _isListening = false;
      
      _logger.i('Cancelled speech recognition');
      return SpeechRecognitionResult.success();
      
    } catch (e) {
      _logger.e('Failed to cancel listening: $e');
      return SpeechRecognitionResult.failure(
        'Failed to cancel speech recognition: $e',
        SpeechRecognitionError.listeningFailed,
      );
    }
  }

  /// Set the locale for speech recognition
  Future<SpeechRecognitionResult> setLocale(String localeId) async {
    try {
      // Check if locale is available
      final localeExists = _availableLocales.any((locale) => locale.localeId == localeId);
      if (!localeExists) {
        return SpeechRecognitionResult.failure(
          'Locale not available: $localeId',
          SpeechRecognitionError.localeNotSupported,
        );
      }

      _selectedLocaleId = localeId;
      _logger.i('Set speech recognition locale to: $localeId');
      
      return SpeechRecognitionResult.success();
      
    } catch (e) {
      _logger.e('Failed to set locale: $e');
      return SpeechRecognitionResult.failure(
        'Failed to set locale: $e',
        SpeechRecognitionError.configurationError,
      );
    }
  }

  /// Convert audio file to text (if supported by platform)
  Future<SpeechRecognitionResult> transcribeAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return SpeechRecognitionResult.failure(
          'Audio file not found',
          SpeechRecognitionError.fileNotFound,
        );
      }

      // Note: speech_to_text doesn't support file transcription directly
      // This would typically require a cloud service like Google Cloud Speech-to-Text
      // For now, return a not supported error
      return SpeechRecognitionResult.failure(
        'Audio file transcription not supported with local speech recognition. Use live speech instead.',
        SpeechRecognitionError.notSupported,
      );
      
    } catch (e) {
      _logger.e('Failed to transcribe audio file: $e');
      return SpeechRecognitionResult.failure(
        'Failed to transcribe audio file: $e',
        SpeechRecognitionError.transcriptionFailed,
      );
    }
  }

  /// Get current sound level (0.0 to 1.0)
  double getSoundLevel() {
    if (!_isInitialized || !_isListening) {
      return 0.0;
    }
    // Note: speech_to_text doesn't provide direct level access in newer versions
    // This would need to be tracked via onSoundLevelChange callback
    return 0.0;
  }

  /// Check if speech recognition has errors
  bool get hasError => _speechToText.hasError;

  /// Get last error message
  String? get lastError => _speechToText.lastError?.errorMsg;

  /// Private methods
  void _setDefaultLocale() {
    // Try to find system locale or fallback to English
    final systemLocale = Platform.localeName;
    final matchingLocale = _availableLocales.firstWhere(
      (locale) => locale.localeId.startsWith(systemLocale.substring(0, 2)),
      orElse: () => _availableLocales.firstWhere(
        (locale) => locale.localeId.startsWith('en'),
        orElse: () => _availableLocales.first,
      ),
    );
    
    _selectedLocaleId = matchingLocale.localeId;
    _logger.d('Selected default locale: $_selectedLocaleId');
  }

  void _onStatusChanged(String status) {
    _logger.d('Speech recognition status: $status');
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  void _onError(dynamic error) {
    _logger.e('Speech recognition error: $error');
    _isListening = false;
  }

  void _onSpeechResult(
    dynamic result,
    Function(String)? onResult,
    Function(String)? onPartialResult,
  ) {
    final recognizedText = result.recognizedWords;
    
    if (result.finalResult) {
      _logger.i('Final speech result: $recognizedText (confidence: ${result.confidence})');
      onResult?.call(recognizedText);
      _isListening = false;
    } else {
      _logger.d('Partial speech result: $recognizedText');
      onPartialResult?.call(recognizedText);
    }
  }

  void _onSoundLevelChange(double level) {
    // Sound level changed - can be used for UI feedback
    // Level is between 0.0 and 1.0
  }

  /// Get supported locales for specific language
  List<stt.LocaleName> getLocalesForLanguage(String languageCode) {
    return _availableLocales.where(
      (locale) => locale.localeId.startsWith(languageCode),
    ).toList();
  }

  /// Check if a specific locale is supported
  bool isLocaleSupported(String localeId) {
    return _availableLocales.any((locale) => locale.localeId == localeId);
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      if (_isListening) {
        await cancelListening();
      }
      _logger.d('Speech recognition service disposed');
    } catch (e) {
      _logger.e('Error disposing speech recognition service: $e');
    }
  }
}

/// Result class for speech recognition operations
class SpeechRecognitionResult {
  final bool isSuccess;
  final String? data;
  final String? errorMessage;
  final SpeechRecognitionError? errorType;

  const SpeechRecognitionResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.errorType,
  });

  factory SpeechRecognitionResult.success([String? data]) {
    return SpeechRecognitionResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory SpeechRecognitionResult.failure(String errorMessage, SpeechRecognitionError errorType) {
    return SpeechRecognitionResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'SpeechRecognitionResult.success(data: $data)';
    } else {
      return 'SpeechRecognitionResult.failure(error: $errorMessage, type: $errorType)';
    }
  }
}

/// Types of speech recognition errors
enum SpeechRecognitionError {
  permissionDenied,
  notSupported,
  initializationFailed,
  listeningFailed,
  transcriptionFailed,
  alreadyListening,
  notListening,
  localeNotSupported,
  configurationError,
  fileNotFound,
}

/// Extension to get human-readable error messages
extension SpeechRecognitionErrorExt on SpeechRecognitionError {
  String get message {
    switch (this) {
      case SpeechRecognitionError.permissionDenied:
        return 'Microphone permission is required for speech recognition';
      case SpeechRecognitionError.notSupported:
        return 'Speech recognition is not supported on this device';
      case SpeechRecognitionError.initializationFailed:
        return 'Failed to initialize speech recognition. Please try again';
      case SpeechRecognitionError.listeningFailed:
        return 'Failed to process speech. Please try again';
      case SpeechRecognitionError.transcriptionFailed:
        return 'Failed to transcribe audio. Please try again';
      case SpeechRecognitionError.alreadyListening:
        return 'Speech recognition is already active';
      case SpeechRecognitionError.notListening:
        return 'Speech recognition is not active';
      case SpeechRecognitionError.localeNotSupported:
        return 'Selected language is not supported';
      case SpeechRecognitionError.configurationError:
        return 'Speech recognition configuration error';
      case SpeechRecognitionError.fileNotFound:
        return 'Audio file not found';
    }
  }
}