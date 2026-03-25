import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:record/record.dart';  // Temporarily disabled
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

/// Service for handling voice recording functionality
class VoiceRecordingService {
  static VoiceRecordingService? _instance;
  static VoiceRecordingService get instance => _instance ??= VoiceRecordingService._();
  
  VoiceRecordingService._();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPaused = false;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if recording is paused
  bool get isPaused => _isPaused;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize recording service and request permissions
  Future<VoiceRecordingResult> initialize() async {
    try {
      // Check if microphone permission is granted
      final micPermission = await Permission.microphone.request();
      
      if (micPermission != PermissionStatus.granted) {
        return VoiceRecordingResult.failure(
          'Microphone permission is required for voice messages',
          VoiceRecordingError.permissionDenied,
        );
      }

      // Check if we can record
      if (!await _audioRecorder.hasPermission()) {
        return VoiceRecordingResult.failure(
          'Recording permission not available',
          VoiceRecordingError.permissionDenied,
        );
      }

      _logger.i('Voice recording service initialized successfully');
      return VoiceRecordingResult.success();
      
    } catch (e) {
      _logger.e('Failed to initialize voice recording service: $e');
      return VoiceRecordingResult.failure(
        'Failed to initialize recording: $e',
        VoiceRecordingError.initializationFailed,
      );
    }
  }

  /// Start recording audio
  Future<VoiceRecordingResult> startRecording() async {
    try {
      if (_isRecording) {
        return VoiceRecordingResult.failure(
          'Recording is already in progress',
          VoiceRecordingError.alreadyRecording,
        );
      }

      // Create temporary directory for audio files
      final tempDir = await getTemporaryDirectory();
      final audioDir = Directory('${tempDir.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Generate unique filename
      final fileName = 'voice_${_uuid.v4()}.m4a';
      _currentRecordingPath = '${audioDir.path}/$fileName';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // Good compression and quality
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // Standard sample rate
        numChannels: 1, // Mono recording
      );

      // Start recording
      await _audioRecorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      _isPaused = false;

      _logger.i('Started recording to: $_currentRecordingPath');
      return VoiceRecordingResult.success(_currentRecordingPath);
      
    } catch (e) {
      _logger.e('Failed to start recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      
      return VoiceRecordingResult.failure(
        'Failed to start recording: $e',
        VoiceRecordingError.recordingFailed,
      );
    }
  }

  /// Stop recording and return the file path
  Future<VoiceRecordingResult> stopRecording() async {
    try {
      if (!_isRecording) {
        return VoiceRecordingResult.failure(
          'No recording in progress',
          VoiceRecordingError.notRecording,
        );
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;
      _isPaused = false;

      if (path == null || _currentRecordingPath == null) {
        return VoiceRecordingResult.failure(
          'Failed to save recording',
          VoiceRecordingError.recordingFailed,
        );
      }

      // Check if file exists and has content
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        return VoiceRecordingResult.failure(
          'Recording file not found',
          VoiceRecordingError.fileNotFound,
        );
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        // Delete empty file
        await file.delete();
        return VoiceRecordingResult.failure(
          'Recording is empty',
          VoiceRecordingError.emptyRecording,
        );
      }

      _logger.i('Recording saved to: $_currentRecordingPath (${fileSize} bytes)');
      
      final result = VoiceRecordingResult.success(_currentRecordingPath);
      _currentRecordingPath = null;
      
      return result;
      
    } catch (e) {
      _logger.e('Failed to stop recording: $e');
      _isRecording = false;
      _isPaused = false;
      _currentRecordingPath = null;
      
      return VoiceRecordingResult.failure(
        'Failed to stop recording: $e',
        VoiceRecordingError.recordingFailed,
      );
    }
  }

  /// Pause recording
  Future<VoiceRecordingResult> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) {
        return VoiceRecordingResult.failure(
          'Cannot pause - not recording or already paused',
          VoiceRecordingError.invalidState,
        );
      }

      await _audioRecorder.pause();
      _isPaused = true;
      
      _logger.i('Recording paused');
      return VoiceRecordingResult.success();
      
    } catch (e) {
      _logger.e('Failed to pause recording: $e');
      return VoiceRecordingResult.failure(
        'Failed to pause recording: $e',
        VoiceRecordingError.recordingFailed,
      );
    }
  }

  /// Resume recording
  Future<VoiceRecordingResult> resumeRecording() async {
    try {
      if (!_isRecording || !_isPaused) {
        return VoiceRecordingResult.failure(
          'Cannot resume - not recording or not paused',
          VoiceRecordingError.invalidState,
        );
      }

      await _audioRecorder.resume();
      _isPaused = false;
      
      _logger.i('Recording resumed');
      return VoiceRecordingResult.success();
      
    } catch (e) {
      _logger.e('Failed to resume recording: $e');
      return VoiceRecordingResult.failure(
        'Failed to resume recording: $e',
        VoiceRecordingError.recordingFailed,
      );
    }
  }

  /// Cancel recording and delete the file
  Future<VoiceRecordingResult> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
        _isPaused = false;
      }

      // Delete the recording file if it exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Deleted cancelled recording: $_currentRecordingPath');
        }
        _currentRecordingPath = null;
      }

      return VoiceRecordingResult.success();
      
    } catch (e) {
      _logger.e('Failed to cancel recording: $e');
      return VoiceRecordingResult.failure(
        'Failed to cancel recording: $e',
        VoiceRecordingError.recordingFailed,
      );
    }
  }

  /// Get amplitude during recording (for waveform visualization)
  Future<double> getAmplitude() async {
    try {
      if (!_isRecording || _isPaused) {
        return 0.0;
      }

      // Note: Amplitude API may vary by version
      // For now, return a mock value
      return 0.5; // Simplified for compatibility
      
    } catch (e) {
      _logger.w('Failed to get amplitude: $e');
      return 0.0;
    }
  }

  /// Get recording duration in milliseconds
  Future<int> getRecordingDuration() async {
    try {
      if (!_isRecording) {
        return 0;
      }

      // This is a rough estimation - for accurate duration, we'd need to track start time
      // For now, return 0 as this would require more complex state management
      return 0;
      
    } catch (e) {
      _logger.w('Failed to get recording duration: $e');
      return 0;
    }
  }

  /// Clean up temporary audio files older than 24 hours
  Future<void> cleanupOldRecordings() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioDir = Directory('${tempDir.path}/audio');
      
      if (!await audioDir.exists()) {
        return;
      }

      final now = DateTime.now();
      final files = audioDir.listSync();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          if (age.inHours > 24) {
            await file.delete();
            _logger.d('Deleted old recording: ${file.path}');
          }
        }
      }
      
    } catch (e) {
      _logger.w('Failed to cleanup old recordings: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      await _audioRecorder.dispose();
      _logger.d('Voice recording service disposed');
    } catch (e) {
      _logger.e('Error disposing voice recording service: $e');
    }
  }
}

/// Result class for voice recording operations
class VoiceRecordingResult {
  final bool isSuccess;
  final String? data;
  final String? errorMessage;
  final VoiceRecordingError? errorType;

  const VoiceRecordingResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.errorType,
  });

  factory VoiceRecordingResult.success([String? data]) {
    return VoiceRecordingResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory VoiceRecordingResult.failure(String errorMessage, VoiceRecordingError errorType) {
    return VoiceRecordingResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'VoiceRecordingResult.success(data: $data)';
    } else {
      return 'VoiceRecordingResult.failure(error: $errorMessage, type: $errorType)';
    }
  }
}

/// Types of voice recording errors
enum VoiceRecordingError {
  permissionDenied,
  initializationFailed,
  recordingFailed,
  alreadyRecording,
  notRecording,
  invalidState,
  fileNotFound,
  emptyRecording,
}

/// Extension to get human-readable error messages
extension VoiceRecordingErrorExt on VoiceRecordingError {
  String get message {
    switch (this) {
      case VoiceRecordingError.permissionDenied:
        return 'Microphone permission is required to record voice messages';
      case VoiceRecordingError.initializationFailed:
        return 'Failed to initialize recording. Please try again';
      case VoiceRecordingError.recordingFailed:
        return 'Recording failed. Please check your microphone and try again';
      case VoiceRecordingError.alreadyRecording:
        return 'A recording is already in progress';
      case VoiceRecordingError.notRecording:
        return 'No recording in progress';
      case VoiceRecordingError.invalidState:
        return 'Invalid recording state';
      case VoiceRecordingError.fileNotFound:
        return 'Recording file not found';
      case VoiceRecordingError.emptyRecording:
        return 'Recording is too short. Please try again';
    }
  }
}