import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling text-to-speech functionality for companion responses
class TextToSpeechService {
  static TextToSpeechService? _instance;
  static TextToSpeechService get instance => _instance ??= TextToSpeechService._();
  
  TextToSpeechService._();

  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  List<dynamic> _availableVoices = [];
  List<String> _availableLanguages = [];
  
  // Default settings
  String _selectedLanguage = 'en-US';
  String? _selectedVoice;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 0.8;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if speech is paused
  bool get isPaused => _isPaused;

  /// Get available voices
  List<dynamic> get availableVoices => _availableVoices;

  /// Get available languages
  List<String> get availableLanguages => _availableLanguages;

  /// Get current settings
  String get selectedLanguage => _selectedLanguage;
  String? get selectedVoice => _selectedVoice;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  /// Initialize text-to-speech service
  Future<TextToSpeechResult> initialize() async {
    try {
      // Set up TTS callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        _logger.d('TTS started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        _logger.d('TTS completed speaking');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        _logger.d('TTS cancelled');
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        _logger.d('TTS paused');
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        _logger.d('TTS resumed');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isPaused = false;
        _logger.e('TTS error: $msg');
      });

      // Get available languages and voices
      _availableLanguages = List<String>.from(await _flutterTts.getLanguages ?? []);
      _availableVoices = await _flutterTts.getVoices ?? [];

      // Set platform-specific configurations
      if (Platform.isAndroid) {
        await _configureAndroid();
      } else if (Platform.isIOS) {
        await _configureIOS();
      }

      // Load saved settings
      await _loadSettings();

      // Apply current settings
      await _applySettings();

      _isInitialized = true;
      _logger.i('Text-to-speech service initialized successfully');
      _logger.d('Available languages: ${_availableLanguages.length}');
      _logger.d('Available voices: ${_availableVoices.length}');
      
      return TextToSpeechResult.success();
      
    } catch (e) {
      _logger.e('Failed to initialize text-to-speech: $e');
      return TextToSpeechResult.failure(
        'Failed to initialize text-to-speech: $e',
        TextToSpeechError.initializationFailed,
      );
    }
  }

  /// Speak the given text
  Future<TextToSpeechResult> speak(String text, {
    String? language,
    String? voice,
    double? speechRate,
    double? pitch,
    double? volume,
  }) async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        if (!initResult.isSuccess) {
          return initResult;
        }
      }

      if (text.trim().isEmpty) {
        return TextToSpeechResult.failure(
          'Cannot speak empty text',
          TextToSpeechError.invalidInput,
        );
      }

      // Stop any current speech
      if (_isSpeaking) {
        await stop();
      }

      // Apply temporary settings if provided
      if (language != null && language != _selectedLanguage) {
        await _flutterTts.setLanguage(language);
      }
      
      if (voice != null && voice != _selectedVoice) {
        await _flutterTts.setVoice({
          'name': voice,
          'locale': language ?? _selectedLanguage,
        });
      }

      if (speechRate != null) {
        await _flutterTts.setSpeechRate(speechRate);
      }

      if (pitch != null) {
        await _flutterTts.setPitch(pitch);
      }

      if (volume != null) {
        await _flutterTts.setVolume(volume);
      }

      // Start speaking
      final result = await _flutterTts.speak(text);
      
      if (result == 1) {
        _logger.i('Started speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
        
        // Restore original settings if temporary settings were used
        if (language != null || voice != null || speechRate != null || pitch != null || volume != null) {
          // Restore after a short delay to not interrupt speech
          Future.delayed(const Duration(milliseconds: 100), () async {
            await _applySettings();
          });
        }
        
        return TextToSpeechResult.success();
      } else {
        return TextToSpeechResult.failure(
          'Failed to start speaking',
          TextToSpeechError.speakingFailed,
        );
      }
      
    } catch (e) {
      _logger.e('Failed to speak text: $e');
      return TextToSpeechResult.failure(
        'Failed to speak text: $e',
        TextToSpeechError.speakingFailed,
      );
    }
  }

  /// Stop speaking
  Future<TextToSpeechResult> stop() async {
    try {
      final result = await _flutterTts.stop();
      _isSpeaking = false;
      _isPaused = false;
      
      if (result == 1) {
        _logger.i('Stopped speaking');
        return TextToSpeechResult.success();
      } else {
        return TextToSpeechResult.failure(
          'Failed to stop speaking',
          TextToSpeechError.controlFailed,
        );
      }
      
    } catch (e) {
      _logger.e('Failed to stop speaking: $e');
      return TextToSpeechResult.failure(
        'Failed to stop speaking: $e',
        TextToSpeechError.controlFailed,
      );
    }
  }

  /// Pause speaking
  Future<TextToSpeechResult> pause() async {
    try {
      if (!_isSpeaking || _isPaused) {
        return TextToSpeechResult.failure(
          'Cannot pause - not speaking or already paused',
          TextToSpeechError.invalidState,
        );
      }

      final result = await _flutterTts.pause();
      
      if (result == 1) {
        _logger.i('Paused speaking');
        return TextToSpeechResult.success();
      } else {
        return TextToSpeechResult.failure(
          'Failed to pause speaking',
          TextToSpeechError.controlFailed,
        );
      }
      
    } catch (e) {
      _logger.e('Failed to pause speaking: $e');
      return TextToSpeechResult.failure(
        'Failed to pause speaking: $e',
        TextToSpeechError.controlFailed,
      );
    }
  }

  /// Resume speaking
  Future<TextToSpeechResult> resume() async {
    try {
      if (!_isPaused) {
        return TextToSpeechResult.failure(
          'Cannot resume - not paused',
          TextToSpeechError.invalidState,
        );
      }

      final result = await _flutterTts.resume();
      
      if (result == 1) {
        _logger.i('Resumed speaking');
        return TextToSpeechResult.success();
      } else {
        return TextToSpeechResult.failure(
          'Failed to resume speaking',
          TextToSpeechError.controlFailed,
        );
      }
      
    } catch (e) {
      _logger.e('Failed to resume speaking: $e');
      return TextToSpeechResult.failure(
        'Failed to resume speaking: $e',
        TextToSpeechError.controlFailed,
      );
    }
  }

  /// Set language
  Future<TextToSpeechResult> setLanguage(String language) async {
    try {
      if (!_availableLanguages.contains(language)) {
        return TextToSpeechResult.failure(
          'Language not supported: $language',
          TextToSpeechError.languageNotSupported,
        );
      }

      await _flutterTts.setLanguage(language);
      _selectedLanguage = language;
      
      // Clear selected voice as it might not be compatible
      _selectedVoice = null;
      
      await _saveSettings();
      _logger.i('Set language to: $language');
      
      return TextToSpeechResult.success();
      
    } catch (e) {
      _logger.e('Failed to set language: $e');
      return TextToSpeechResult.failure(
        'Failed to set language: $e',
        TextToSpeechError.configurationError,
      );
    }
  }

  /// Set voice
  Future<TextToSpeechResult> setVoice(String voiceName) async {
    try {
      final voice = _availableVoices.firstWhere(
        (v) => v['name'] == voiceName,
        orElse: () => null,
      );

      if (voice == null) {
        return TextToSpeechResult.failure(
          'Voice not found: $voiceName',
          TextToSpeechError.voiceNotSupported,
        );
      }

      await _flutterTts.setVoice({
        'name': voiceName,
        'locale': voice['locale'] ?? _selectedLanguage,
      });
      
      _selectedVoice = voiceName;
      await _saveSettings();
      
      _logger.i('Set voice to: $voiceName');
      return TextToSpeechResult.success();
      
    } catch (e) {
      _logger.e('Failed to set voice: $e');
      return TextToSpeechResult.failure(
        'Failed to set voice: $e',
        TextToSpeechError.configurationError,
      );
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<TextToSpeechResult> setSpeechRate(double rate) async {
    try {
      if (rate < 0.0 || rate > 1.0) {
        return TextToSpeechResult.failure(
          'Speech rate must be between 0.0 and 1.0',
          TextToSpeechError.invalidInput,
        );
      }

      await _flutterTts.setSpeechRate(rate);
      _speechRate = rate;
      await _saveSettings();
      
      _logger.i('Set speech rate to: $rate');
      return TextToSpeechResult.success();
      
    } catch (e) {
      _logger.e('Failed to set speech rate: $e');
      return TextToSpeechResult.failure(
        'Failed to set speech rate: $e',
        TextToSpeechError.configurationError,
      );
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<TextToSpeechResult> setPitch(double pitch) async {
    try {
      if (pitch < 0.5 || pitch > 2.0) {
        return TextToSpeechResult.failure(
          'Pitch must be between 0.5 and 2.0',
          TextToSpeechError.invalidInput,
        );
      }

      await _flutterTts.setPitch(pitch);
      _pitch = pitch;
      await _saveSettings();
      
      _logger.i('Set pitch to: $pitch');
      return TextToSpeechResult.success();
      
    } catch (e) {
      _logger.e('Failed to set pitch: $e');
      return TextToSpeechResult.failure(
        'Failed to set pitch: $e',
        TextToSpeechError.configurationError,
      );
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<TextToSpeechResult> setVolume(double volume) async {
    try {
      if (volume < 0.0 || volume > 1.0) {
        return TextToSpeechResult.failure(
          'Volume must be between 0.0 and 1.0',
          TextToSpeechError.invalidInput,
        );
      }

      await _flutterTts.setVolume(volume);
      _volume = volume;
      await _saveSettings();
      
      _logger.i('Set volume to: $volume');
      return TextToSpeechResult.success();
      
    } catch (e) {
      _logger.e('Failed to set volume: $e');
      return TextToSpeechResult.failure(
        'Failed to set volume: $e',
        TextToSpeechError.configurationError,
      );
    }
  }

  /// Get voices for specific language
  List<dynamic> getVoicesForLanguage(String language) {
    return _availableVoices.where((voice) {
      final voiceLocale = voice['locale'] as String?;
      return voiceLocale != null && voiceLocale.startsWith(language.substring(0, 2));
    }).toList();
  }

  /// Private methods
  Future<void> _configureAndroid() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.allowBluetooth],
      IosTextToSpeechAudioMode.defaultMode,
    );
  }

  Future<void> _configureIOS() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.allowAirPlay,
      ],
      IosTextToSpeechAudioMode.spokenAudio,
    );
  }

  Future<void> _applySettings() async {
    await _flutterTts.setLanguage(_selectedLanguage);
    
    if (_selectedVoice != null) {
      await _flutterTts.setVoice({
        'name': _selectedVoice!,
        'locale': _selectedLanguage,
      });
    }
    
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(_volume);
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _selectedLanguage = prefs.getString('tts_language') ?? 'en-US';
      _selectedVoice = prefs.getString('tts_voice');
      _speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
      _pitch = prefs.getDouble('tts_pitch') ?? 1.0;
      _volume = prefs.getDouble('tts_volume') ?? 0.8;
      
      _logger.d('Loaded TTS settings: language=$_selectedLanguage, voice=$_selectedVoice');
      
    } catch (e) {
      _logger.w('Failed to load TTS settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('tts_language', _selectedLanguage);
      if (_selectedVoice != null) {
        await prefs.setString('tts_voice', _selectedVoice!);
      }
      await prefs.setDouble('tts_speech_rate', _speechRate);
      await prefs.setDouble('tts_pitch', _pitch);
      await prefs.setDouble('tts_volume', _volume);
      
    } catch (e) {
      _logger.w('Failed to save TTS settings: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      if (_isSpeaking) {
        await stop();
      }
      _logger.d('Text-to-speech service disposed');
    } catch (e) {
      _logger.e('Error disposing text-to-speech service: $e');
    }
  }
}

/// Result class for text-to-speech operations
class TextToSpeechResult {
  final bool isSuccess;
  final String? data;
  final String? errorMessage;
  final TextToSpeechError? errorType;

  const TextToSpeechResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.errorType,
  });

  factory TextToSpeechResult.success([String? data]) {
    return TextToSpeechResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory TextToSpeechResult.failure(String errorMessage, TextToSpeechError errorType) {
    return TextToSpeechResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'TextToSpeechResult.success(data: $data)';
    } else {
      return 'TextToSpeechResult.failure(error: $errorMessage, type: $errorType)';
    }
  }
}

/// Types of text-to-speech errors
enum TextToSpeechError {
  initializationFailed,
  speakingFailed,
  controlFailed,
  invalidState,
  invalidInput,
  languageNotSupported,
  voiceNotSupported,
  configurationError,
}

/// Extension to get human-readable error messages
extension TextToSpeechErrorExt on TextToSpeechError {
  String get message {
    switch (this) {
      case TextToSpeechError.initializationFailed:
        return 'Failed to initialize text-to-speech. Please try again';
      case TextToSpeechError.speakingFailed:
        return 'Failed to speak text. Please try again';
      case TextToSpeechError.controlFailed:
        return 'Failed to control speech playback';
      case TextToSpeechError.invalidState:
        return 'Invalid speech state for this operation';
      case TextToSpeechError.invalidInput:
        return 'Invalid input parameters';
      case TextToSpeechError.languageNotSupported:
        return 'Selected language is not supported';
      case TextToSpeechError.voiceNotSupported:
        return 'Selected voice is not supported';
      case TextToSpeechError.configurationError:
        return 'Speech configuration error';
    }
  }
}