// lib/core/services/transcription_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:skrybe/data/models/transcript_model.dart';
import 'package:uuid/uuid.dart';

class TranscriptionService {
  final Dio _dio;
  final FirebaseStorage _storage;

  TranscriptionService({
    required Dio dio,
    required FirebaseStorage storage,
  })  : _dio = dio,
        _storage = storage;

  // Upload audio file to Firebase Storage
  Future<String> uploadAudioFile(File file, String userId) async {
    final fileName = '${const Uuid().v4()}${path.extension(file.path)}';
    final storageRef = _storage.ref().child('audio/$userId/$fileName');

    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(
          contentType:
              'audio/${path.extension(file.path).replaceAll('.', '')}'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Extract audio from video file
  Future<File> extractAudioFromVideo(File videoFile) async {
    // In a real application, you would use a package like ffmpeg_kit_flutter
    // to extract audio from video. For this example, we'll simulate it.

    // Simulated audio extraction
    final directory = path.dirname(videoFile.path);
    final fileName = path.basenameWithoutExtension(videoFile.path);
    final audioPath = '$directory/$fileName.mp3';

    // In a real app, you would process the video here
    // For now, we'll just create an empty audio file
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      await audioFile.create();
    }

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    return audioFile;
  }

  // Transcribe audio using OpenAI Whisper API
  Future<String> transcribeWithWhisper(String audioUrl) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found');
    }

    try {
      // Download the audio file
      final response = await _dio.get(
        audioUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final audioBytes = response.data as List<int>;
      final audioFile = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          audioBytes,
          filename: 'audio.mp3',
        ),
        'model': 'whisper-1',
        'response_format': 'text',
      });

      // Send to OpenAI API
      final transcriptionResponse = await _dio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: audioFile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      return transcriptionResponse.data as String;
    } catch (e) {
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  // Transcribe audio using Google Speech-to-Text (alternative option)
  Future<String> transcribeWithGoogleSpeech(String audioUrl) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null) {
      throw Exception('Google API key not found');
    }

    try {
      // Download the audio file
      final response = await _dio.get(
        audioUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final audioBytes = response.data as List<int>;
      final audioBase64 = base64Encode(audioBytes);

      // Send to Google Speech-to-Text API
      final transcriptionResponse = await _dio.post(
        'https://speech.googleapis.com/v1p1beta1/speech:recognize?key=$apiKey',
        data: {
          'config': {
            'enableAutomaticPunctuation': true,
            'languageCode': 'en-US',
            'model': 'default',
          },
          'audio': {
            'content': audioBase64,
          },
        },
      );

      final results = transcriptionResponse.data['results'] as List;
      if (results.isEmpty) return '';

      final alternatives = results[0]['alternatives'] as List;
      if (alternatives.isEmpty) return '';

      return alternatives[0]['transcript'] as String;
    } catch (e) {
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  // Analyze transcript to detect speakers
  Future<List<String>> detectSpeakers(String transcript) async {
    // In a real application, this would use NLP or a dedicated API
    // For this example, we'll simulate it

    // Simulated speaker detection
    final speakers = <String>[];

    // Simple regex to find patterns like "John: " or "Speaker 1: "
    final regex = RegExp(r'([A-Za-z0-9\s]+):\s');
    final matches = regex.allMatches(transcript);

    for (final match in matches) {
      final speaker = match.group(1)?.trim();
      if (speaker != null && !speakers.contains(speaker)) {
        speakers.add(speaker);
      }
    }

    // If no speakers detected, add default ones
    if (speakers.isEmpty) {
      speakers.add('Speaker 1');

      // Check if there's likely more than one speaker by looking for common patterns
      if (transcript.contains('\n\n') ||
          transcript.toLowerCase().contains('question:') ||
          transcript.toLowerCase().contains('answer:')) {
        speakers.add('Speaker 2');
      }
    }

    return speakers;
  }

  // Generate a summary of the transcript
  Future<String> generateSummary(String transcript) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found');
    }

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant that summarizes transcripts concisely.',
            },
            {
              'role': 'user',
              'content':
                  'Summarize this transcript in 3-5 sentences: $transcript',
            },
          ],
          'max_tokens': 150,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to generate summary: $e');
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(firebaseStorageProvider);

  return TranscriptionService(
    dio: dio,
    storage: storage,
  );
});
