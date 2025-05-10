import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

// Replaceed ffmpeg_kit with media_kit
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:skrybe/data/models/transcription_model.dart';
import 'package:skrybe/data/models/transcript_model.dart';

/// Service responsible for audio/video processing and transcription
class TranscriptionService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final _uuid = const Uuid();

  // Make sure to initialize Media Kit in your app's main.dart:
  // void main() {
  //   MediaKit.ensureInitialized();
  //   runApp(MyApp());
  // }

  /// Process an audio recording for transcription
  ///
  /// Takes a local audio file, uploads it to Firebase Storage, processes it via Cloud Functions,
  /// and returns a TranscriptionModel with the results
  Future<TranscriptionModel> processRecording(
      File audioFile, String title, String userId) async {
    try {
      debugPrint('Starting processing of recording: $title');

      // Generate a unique ID for this transcription
      final transcriptionId = _uuid.v4();

      // Create a basic transcription model in "processing" state
      final initialTranscription = TranscriptionModel(
        id: transcriptionId,
        userId: userId,
        title: title.isEmpty
            ? 'Recording ${DateTime.now().toString().substring(0, 16)}'
            : title,
        content: '',
        source: TranscriptionSource.recording,
        status: TranscriptionStatus.processing,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: [],
      );

      // Upload the audio file to Firebase Storage
      final audioUrl = await _uploadAudioFile(audioFile, transcriptionId);

      // Get audio duration
      final duration = await _getAudioDuration(audioFile);

      // Request transcription through Firebase Functions
      final transcriptionResult =
          await _requestTranscription(audioUrl, transcriptionId);

      // Create updated transcription with results
      return initialTranscription.copyWith(
        content: transcriptionResult.content,
        rawaudioUrl: audioUrl,
        status: TranscriptionStatus.completed,
        duration: Duration(milliseconds: (duration * 1000).toInt()),
        speakers: transcriptionResult.speakers,
        metadata: {
          'processingTimeMs': transcriptionResult.metadata?['processingTimeMs'],
          'wordCount': transcriptionResult.content.split(' ').length,
          'processingDate': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error processing recording: $e');

      // Create error transcription model
      return TranscriptionModel(
        id: _uuid.v4(),
        userId: userId,
        title: title.isEmpty ? 'Failed Recording' : title,
        content: '',
        source: TranscriptionSource.recording,
        status: TranscriptionStatus.failed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Extract audio from a video file
  ///
  /// Uses MediaKit to extract audio from video into a temporary mp3 file
  Future<File> extractAudioFromVideo(File videoFile) async {
    try {
      debugPrint('Extracting audio from video file: ${videoFile.path}');

      // Create a temporary directory to store the extracted audio
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(tempDir.path, '${_uuid.v4()}.mp3');

      // Create a player instance
      final player = Player();

      // Open the video file
      await player.open(Media(videoFile.path));

      // // Use MediaKit to extract audio
      // await player.platform.extractAudio(
      //   outputPath,
      //   format: 'mp3',
      //   bitrate: '192k',
      // );
      // Replace the extractAudioFromVideo method with this implementation:
      Future<File> extractAudioFromVideo(File videoFile) async {
        try {
          debugPrint('Extracting audio from video file: ${videoFile.path}');

          // Create a temporary directory to store the extracted audio
          final tempDir = await getTemporaryDirectory();
          final outputPath = path.join(tempDir.path, '${_uuid.v4()}.mp3');

          // Use FFmpeg commands directly through process
          final result = await Process.run(
            'ffmpeg',
            [
              '-i', videoFile.path,
              '-vn', // No video
              '-acodec', 'libmp3lame',
              '-ab', '192k',
              '-ar', '44100',
              outputPath
            ],
          );

          if (result.exitCode != 0) {
            throw Exception('Audio extraction failed: ${result.stderr}');
          }

          // Verify the output file exists
          final outputFile = File(outputPath);
          if (!await outputFile.exists()) {
            throw Exception(
                'Audio extraction failed: Output file does not exist');
          }

          return outputFile;
        } catch (e) {
          debugPrint('Error extracting audio from video: $e');
          rethrow;
        }
      }

      // Dispose the player
      await player.dispose();

      // Verify the output file exists
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Audio extraction failed: Output file does not exist');
      }

      return outputFile;
    } catch (e) {
      debugPrint('Error extracting audio from video: $e');
      rethrow;
    }
  }

  /// Process a video file for transcription
  ///
  /// Extracts audio from video, then processes it for transcription
  Future<TranscriptionModel> processVideoFile(
      File videoFile, String title, String userId) async {
    try {
      debugPrint('Processing video file for transcription: $title');

      // Generate a unique ID
      final transcriptionId = _uuid.v4();

      // Create initial transcription model
      final initialTranscription = TranscriptionModel(
        id: transcriptionId,
        userId: userId,
        title: title.isEmpty
            ? 'Video ${DateTime.now().toString().substring(0, 16)}'
            : title,
        content: '',
        source: TranscriptionSource.videoUpload,
        status: TranscriptionStatus.processing,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Extract audio from video
      final audioFile = await extractAudioFromVideo(videoFile);

      // Upload both video and audio files
      final videoUrl = await _uploadVideoFile(videoFile, transcriptionId);
      final audioUrl = await _uploadAudioFile(audioFile, transcriptionId);

      // Get video duration
      final duration = await _getVideoDuration(videoFile);

      // Request transcription
      final transcriptionResult =
          await _requestTranscription(audioUrl, transcriptionId);

      // Clean up temporary audio file
      try {
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } catch (e) {
        debugPrint('Warning: Could not delete temporary audio file: $e');
      }

      // Return updated transcription model
      return initialTranscription.copyWith(
        content: transcriptionResult.content,
        rawaudioUrl: audioUrl,
        rawvideoUrl: videoUrl,
        status: TranscriptionStatus.completed,
        duration: Duration(milliseconds: (duration * 1000).toInt()),
        speakers: transcriptionResult.speakers,
        metadata: {
          'processingTimeMs': transcriptionResult.metadata?['processingTimeMs'],
          'wordCount': transcriptionResult.content.split(' ').length,
          'processingDate': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error processing video file: $e');

      // Create error transcription model
      return TranscriptionModel(
        id: _uuid.v4(),
        userId: userId,
        title: title.isEmpty ? 'Failed Video Upload' : title,
        content: '',
        source: TranscriptionSource.videoUpload,
        status: TranscriptionStatus.failed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Generate transcript segments from raw transcription
  ///
  /// Creates time-aligned segments from a full transcript text
  List<TranscriptSegment> generateSegments(String text, double totalDuration) {
    final List<TranscriptSegment> segments = [];

    // Split text by sentences (simple approach)
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));

    // Calculate approximate segment duration
    final segmentDuration = (totalDuration * 1000 / sentences.length).round();

    int startTime = 0;
    for (final sentence in sentences) {
      if (sentence.trim().isEmpty) continue;

      final endTime = startTime + segmentDuration;

      segments.add(TranscriptSegment(
        startTime: startTime,
        endTime: endTime,
        text: sentence.trim(),
        confidence: 0.95, // Placeholder confidence
      ));

      startTime = endTime;
    }

    return segments;
  }

  /// Detect speakers in a transcript (simplified implementation)
  ///
  /// In a real scenario, this would use more sophisticated speaker diarization
  List<String> detectSpeakers(String text) {
    // Simplified implementation
    // In production, this would connect to a more sophisticated speaker diarization service

    final speakerMatches = RegExp(r'(Speaker \d+|Person [A-Z]|[A-Z][a-z]+)\s*:')
        .allMatches(text)
        .map((m) => m.group(1))
        .toSet();

    if (speakerMatches.isEmpty) {
      return ['Speaker 1'];
    }

    return speakerMatches.where((s) => s != null).map((s) => s!).toList();
  }

  /// Upload an audio file to Firebase Storage
  Future<String> _uploadAudioFile(
      File audioFile, String transcriptionId) async {
    final userId = _auth.currentUser!.uid;
    final fileExtension = path.extension(audioFile.path);
    final storageRef = _storage
        .ref()
        .child('users/$userId/audio/$transcriptionId$fileExtension');

    final uploadTask = storageRef.putFile(audioFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload a video file to Firebase Storage
  Future<String> _uploadVideoFile(
      File videoFile, String transcriptionId) async {
    final userId = _auth.currentUser!.uid;
    final fileExtension = path.extension(videoFile.path);
    final storageRef = _storage
        .ref()
        .child('users/$userId/video/$transcriptionId$fileExtension');

    final uploadTask = storageRef.putFile(videoFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Get audio file duration using MediaKit
  Future<double> _getAudioDuration(File audioFile) async {
    try {
      final player = Player();
      await player.open(Media(audioFile.path));

      // Wait for the player to load the media
      await Future.delayed(const Duration(milliseconds: 300));

      // Get duration in milliseconds
// Wait a moment for player to load media metadata
      await Future.delayed(const Duration(milliseconds: 500));
      final durationMs = player.state.duration.inMilliseconds;
      // Close the player
      await player.dispose();

      return durationMs / 1000.0; // Convert ms to seconds
    } catch (e) {
      debugPrint('Error getting audio duration: $e');
      return 0; // Return 0 as default duration on error
    }
  }

  /// Get video file duration using MediaKit
  Future<double> _getVideoDuration(File videoFile) async {
    try {
      final player = Player();
      await player.open(Media(videoFile.path));

      // Wait for the player to load the media
      await Future.delayed(const Duration(milliseconds: 300));

      // Get duration in milliseconds
// Wait a moment for player to load media metadata
      await Future.delayed(const Duration(milliseconds: 500));
      final durationMs = player.state.duration.inMilliseconds;
      // Close the player
      await player.dispose();

      return durationMs / 1000.0; // Convert ms to seconds
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return 0; // Return 0 as default duration on error
    }
  }

  /// Request transcription via Firebase Cloud Functions
  Future<TranscriptionModel> _requestTranscription(
      String audioUrl, String transcriptionId) async {
    try {
      // Call the Cloud Function for transcription
      final result = await _functions.httpsCallable('transcribeAudio').call({
        'audioUrl': audioUrl,
        'transcriptionId': transcriptionId,
        'language': 'en-US', // Default language
        'enableSpeakerDiarization': true,
      });

      final data = result.data;

      if (data == null || data['success'] != true) {
        throw Exception(
            'Transcription failed: ${data?['error'] ?? 'Unknown error'}');
      }

      // Extract content and other data
      final content = data['transcript'] ?? '';
      final speakers = data['speakers'] != null
          ? List<String>.from(data['speakers'])
          : detectSpeakers(content);

      return TranscriptionModel(
        id: transcriptionId,
        userId: _auth.currentUser!.uid,
        title: 'Transcription $transcriptionId',
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: TranscriptionStatus.completed,
        source: TranscriptionSource.recording,
        speakers: speakers,
        metadata: {
          'processingTimeMs': data['processingTimeMs'],
          'confidence': data['confidence'] ?? 0.9,
        },
      );
    } catch (e) {
      debugPrint('Error requesting transcription: $e');

      // If the cloud function fails, we can fall back to a local/basic transcription
      // In a real app, this might use on-device speech recognition or a different API
      return _fallbackTranscription(audioUrl, transcriptionId);
    }
  }

  /// Fallback transcription method when cloud functions fail
  ///
  /// This is a simplified implementation for demonstration
  Future<TranscriptionModel> _fallbackTranscription(
      String audioUrl, String transcriptionId) async {
    try {
      // In a real implementation, this might use an alternative API or on-device processing
      return TranscriptionModel(
        id: transcriptionId,
        userId: _auth.currentUser!.uid,
        title: 'Transcription $transcriptionId',
        content:
            'Fallback transcription content. The cloud transcription service was unavailable.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: TranscriptionStatus.completed,
        source: TranscriptionSource.recording,
        metadata: {
          'note':
              'This is a fallback transcription using simplified processing',
          'processingMethod': 'fallback',
        },
      );
    } catch (e) {
      debugPrint('Error in fallback transcription: $e');
      rethrow;
    }
  }

  /// Generate a summary of the transcription using an AI service
  Future<String> generateSummary(String content) async {
    try {
      // Call the summarization cloud function
      final result = await _functions.httpsCallable('generateSummary').call({
        'text': content,
        'maxLength': 250, // Target summary length in words
      });

      final data = result.data;

      if (data == null || data['success'] != true) {
        throw Exception(
            'Summary generation failed: ${data?['error'] ?? 'Unknown error'}');
      }

      return data['summary'] ?? 'No summary available';
    } catch (e) {
      debugPrint('Error generating summary: $e');
      // Return simplified summary on error
      return _generateBasicSummary(content);
    }
  }

  /// Create a basic summary from the content when AI service fails
  String _generateBasicSummary(String content) {
    // Simple approach: take first ~100 words or so
    final words = content.split(' ');
    if (words.length <= 50) return content;

    return '${words.take(50).join(' ')}...';
  }

  /// Extract keywords from transcript text
  List<String> extractKeywords(String text) {
    // Simple implementation: look for capitalized words and other patterns
    // In a real app, this would use NLP or AI services

    final words = text.split(' ');
    final keywordSet = <String>{};

    // Get capitalized words not at the start of sentences
    for (int i = 1; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r'[^\w]'), '');
      if (word.isNotEmpty &&
          word[0] == word[0].toUpperCase() &&
          !_commonWords.contains(word.toLowerCase())) {
        keywordSet.add(word);
      }
    }

    // Find words that appear frequently
    final wordCounts = <String, int>{};
    for (final word in words) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.length > 4 && !_commonWords.contains(cleanWord)) {
        wordCounts[cleanWord] = (wordCounts[cleanWord] ?? 0) + 1;
      }
    }

    // Add frequent words as keywords
    final frequentWords = wordCounts.entries
        .where((entry) => entry.value >= 3)
        .map((entry) => entry.key)
        .toList();

    keywordSet.addAll(frequentWords);

    // Limit to 10 keywords
    final keywords = keywordSet.take(10).toList();
    return keywords;
  }

  // A short list of common words to filter out from keywords
  final _commonWords = {
    'the',
    'and',
    'that',
    'have',
    'for',
    'not',
    'with',
    'you',
    'this',
    'but',
    'his',
    'from',
    'they',
    'she',
    'will',
    'would',
    'there',
    'their',
    'what',
    'about',
    'which',
    'when',
    'make',
    'like',
    'time',
    'just',
    'know',
    'people',
    'year',
    'your',
    'good',
    'some',
    'could',
    'them',
    'than',
    'then',
    'look',
    'these',
    'other',
    'been',
    'were',
    'because'
  };
}
