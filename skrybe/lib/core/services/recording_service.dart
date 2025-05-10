import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record_platform_interface/record_platform_interface.dart';
import 'package:uuid/uuid.dart';

// Import Record properly
import 'package:record/record.dart';

/// Service responsible for handling audio recording operations
class RecordingService {
  // Create an instance of the AudioRecorder (not Record)
  final _audioRecorder = AudioRecorder();
  final _uuid = const Uuid();

  // Streams
  final _durationStreamController = StreamController<Duration>.broadcast();
  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _recordDurationSubscription;

  // Properties
  String? _currentRecordingPath;
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Timer? _amplitudeTimer;

  // Getters
  bool get isRecording => _isRecording;
  Stream<Duration> get durationStream => _durationStreamController.stream;
  Stream<double> get amplitudeStream => _amplitudeStreamController.stream;

  // Amplitude handling
  final _amplitudeStreamController = StreamController<double>.broadcast();

  /// Initializes the recording service
  Future<void> initialize() async {
    // Handle cleanup of any prior instances
    await _disposeStreams();

    // Check for recording permissions
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission is required.');
    }
  }

  /// Start recording audio
  Future<String> startRecording() async {
    if (_isRecording) {
      throw Exception('Recording is already in progress.');
    }

    // Reset any previous streams
    await _disposeStreams();

    // Ensure permissions before recording
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission is required.');
    }

    // Generate a unique file path for this recording
    final directory = await getTemporaryDirectory();
    final fileName = '${_uuid.v4()}.m4a';
    final path = '${directory.path}/$fileName';

    // Configure recording options - updated for the correct API
    await _audioRecorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc, // High quality audio
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // 44.1 kHz
      ),
      path: path,
    );

    _currentRecordingPath = path;
    _isRecording = true;
    _recordingStartTime = DateTime.now();

    // Start duration tracking
    _startDurationTracking();

    // Start amplitude monitoring
    _startAmplitudeMonitoring();

    return path;
  }

  /// Stop the current recording
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }

    _isRecording = false;
    await _audioRecorder.stop();
    await _disposeStreams();

    return _currentRecordingPath;
  }

  /// Delete the current recording file
  Future<void> deleteRecording() async {
    final path = _currentRecordingPath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting recording: $e');
      }
    }
    _currentRecordingPath = null;
  }

  /// Get the amplitude of the current recording
  Future<double> getAmplitude() async {
    if (!_isRecording) {
      return 0.0;
    }

    // Get the actual amplitude from the recorder - updated for the correct API
    final amplitude = await _audioRecorder.getAmplitude();
    // The max value is typically around 0, and min around -160
    // Normalize to a 0-100 scale for the UI
    final normalized = ((amplitude.current + 160) / 160) * 100;
    return normalized.clamp(0.0, 100.0);
  }

  /// Start monitoring amplitude changes
  void _startAmplitudeMonitoring() {
    // Cancel any existing amplitude monitoring
    _amplitudeTimer?.cancel();

    // Monitor amplitude at regular intervals
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 150), (_) async {
      if (_isRecording) {
        try {
          final amplitude = await getAmplitude();
          _amplitudeStreamController.add(amplitude);
        } catch (e) {
          debugPrint('Error getting amplitude: $e');
        }
      }
    });
  }

  /// Start tracking recording duration
  void _startDurationTracking() {
    // Cancel any existing duration tracking
    _recordDurationSubscription?.cancel();

    // Emit duration updates every second
    _recordDurationSubscription =
        Stream.periodic(const Duration(milliseconds: 100), (_) {
      if (_recordingStartTime != null && _isRecording) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        return duration;
      }
      return Duration.zero;
    }).listen((duration) {
      _durationStreamController.add(duration);
    });
  }

  /// Clean up resources
  Future<void> _disposeStreams() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    await _recordDurationSubscription?.cancel();
    _recordDurationSubscription = null;
  }

  /// Dispose the service and clean up resources
  Future<void> dispose() async {
    await _disposeStreams();
    await _durationStreamController.close();
    await _amplitudeStreamController.close();
  }
}
