import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

/// Mock Voice Recording Service (temporarily replacing real implementation)
/// The real implementation uses the 'record' package which has compatibility issues
class VoiceRecordingService {
  static VoiceRecordingService? _instance;
  static VoiceRecordingService get instance => _instance ??= VoiceRecordingService._();
  
  VoiceRecordingService._();

  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPaused = false;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<VoiceRecordingResult> initialize() async {
    try {
      final micPermission = await Permission.microphone.request();
      
      if (micPermission != PermissionStatus.granted) {
        return VoiceRecordingResult.failure(
          'Microphone permission is required for voice messages',
          VoiceRecordingError.permissionDenied,
        );
      }

      _logger.i('Voice recording service initialized (mock mode)');
      return VoiceRecordingResult.success();
      
    } catch (e) {
      _logger.e('Failed to initialize voice recording service: $e');
      return VoiceRecordingResult.failure(
        'Failed to initialize recording: $e',
        VoiceRecordingError.initializationFailed,
      );
    }
  }

  Future<VoiceRecordingResult> startRecording() async {
    try {
      if (_isRecording) {
        return VoiceRecordingResult.failure(
          'Recording is already in progress',
          VoiceRecordingError.alreadyRecording,
        );
      }

      final tempDir = await getTemporaryDirectory();
      final audioDir = Directory('${tempDir.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = 'voice_${_uuid.v4()}.m4a';
      _currentRecordingPath = '${audioDir.path}/$fileName';

      // Mock recording start
      _isRecording = true;
      _isPaused = false;

      _logger.i('Mock recording started: $_currentRecordingPath');
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

  Future<VoiceRecordingResult> stopRecording() async {
    try {
      if (!_isRecording) {
        return VoiceRecordingResult.failure(
          'No recording in progress',
          VoiceRecordingError.notRecording,
        );
      }

      _isRecording = false;
      _isPaused = false;

      // In mock mode, just return a success with a placeholder path
      _logger.i('Mock recording stopped: $_currentRecordingPath');
      
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

  Future<VoiceRecordingResult> pauseRecording() async {
    if (!_isRecording || _isPaused) {
      return VoiceRecordingResult.failure(
        'Cannot pause - not recording or already paused',
        VoiceRecordingError.invalidState,
      );
    }

    _isPaused = true;
    _logger.i('Mock recording paused');
    return VoiceRecordingResult.success();
  }

  Future<VoiceRecordingResult> resumeRecording() async {
    if (!_isRecording || !_isPaused) {
      return VoiceRecordingResult.failure(
        'Cannot resume - not recording or not paused',
        VoiceRecordingError.invalidState,
      );
    }

    _isPaused = false;
    _logger.i('Mock recording resumed');
    return VoiceRecordingResult.success();
  }

  Future<VoiceRecordingResult> cancelRecording() async {
    _isRecording = false;
    _isPaused = false;
    _currentRecordingPath = null;
    return VoiceRecordingResult.success();
  }

  Future<double> getAmplitude() async {
    return _isRecording && !_isPaused ? 0.5 : 0.0;
  }

  Future<int> getRecordingDuration() async {
    return 0;
  }

  Future<void> cleanupOldRecordings() async {
    _logger.d('Cleanup old recordings (mock - no-op)');
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await cancelRecording();
    }
    _logger.d('Voice recording service disposed (mock)');
  }
}

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