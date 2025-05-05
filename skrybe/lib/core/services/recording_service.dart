// lib/core/services/recording_service.dart
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { initial, recording, paused, stopped, error }

class RecordingService {
  final AudioRecorder _recorder;

  RecordingService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  // Check if app has permission to record audio
  Future<bool> checkPermission() async {
    return await _recorder.hasPermission();
  }

  // Start recording
  Future<void> startRecording() async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/${const Uuid().v4()}.m4a';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );
  }

  // Pause recording
  Future<void> pauseRecording() async {
    await _recorder.pause();
  }

  // Resume recording
  Future<void> resumeRecording() async {
    await _recorder.resume();
  }

  // Stop recording and return the file path
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  // Get the recording file from path
  Future<File?> getRecordingFile(String? path) async {
    if (path == null) return null;
    return File(path);
  }

  // Get recording duration and amplitude
  Stream<Duration> getRecordingDuration() {
    return Stream.periodic(const Duration(milliseconds: 100), (count) async {
      final amplitude = await _recorder.getAmplitude();
      return Duration(milliseconds: count * 100);
    }).asyncMap((future) async => await future);
  }

  // Check if recording is in progress
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // Dispose resources
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

// // lib/core/services/recording_service.dart
// import 'dart:async';
// import 'dart:io';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
// import 'package:uuid/uuid.dart';

// enum RecordingState { initial, recording, paused, stopped, error }

// class RecordingService {
//   final Record _recorder;

//   RecordingService({required Record recorder}) : _recorder = recorder;

//   // Check if app has permission to record audio
//   Future<bool> checkPermission() async {
//     return await _recorder.hasPermission();
//   }

//   // Start recording
//   Future<void> startRecording() async {
//     final directory = await getTemporaryDirectory();
//     final filePath = '${directory.path}/${const Uuid().v4()}.m4a';

//     await _recorder.start(
//       path: filePath,
//       encoder: AudioEncoder.aacLc,
//       bitRate: 128000,
//       samplingRate: 44100,
//     );
//   }

//   // Pause recording
//   Future<void> pauseRecording() async {
//     await _recorder.pause();
//   }

//   // Resume recording
//   Future<void> resumeRecording() async {
//     await _recorder.resume();
//   }

//   // Stop recording and return the file path
//   Future<String?> stopRecording() async {
//     final path = await _recorder.stop();
//     return path;
//   }

//   // Get the recording file from path
//   Future<File?> getRecordingFile(String? path) async {
//     if (path == null) return null;
//     return File(path);
//   }

//   // Get recording duration
//   Stream<Duration> getRecordingDuration() {
//     return Stream.periodic(const Duration(milliseconds: 100), (count) {
//       final amplitude = _recorder.getAmplitude();
//       return Duration(milliseconds: count * 100);
//     });
//   }

//   // Check if recording is in progress
//   Future<bool> isRecording() async {
//     return await _recorder.isRecording();
//   }

//   // Dispose resources
//   Future<void> dispose() async {
//     await _recorder.dispose();
//   }
// }
