import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:skrybe/core/services/transcription_service.dart';
import 'package:skrybe/data/models/transcript_model.dart';
import 'package:skrybe/data/models/transcription_model.dart';
import 'package:uuid/uuid.dart';

class TranscriptionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final TranscriptionService _transcriptionService;
  final _uuid = const Uuid();

  TranscriptionRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
    required FirebaseFunctions functions,
    required TranscriptionService transcriptionService,
  })  : _firestore = firestore,
        _storage = storage,
        _auth = auth,
        _functions = functions,
        _transcriptionService = transcriptionService;

  // Get all transcriptions for the current user
  Stream<List<TranscriptionModel>> getAllTranscriptions() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('transcriptions')
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TranscriptionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get a specific transcription by ID
  Future<TranscriptionModel> getTranscriptById(String id) async {
    try {
      final doc = await _firestore.collection('transcriptions').doc(id).get();
      if (!doc.exists) {
        throw Exception('Transcription not found');
      }
      return TranscriptionModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting transcript by ID: $e');
      rethrow;
    }
  }

  // Create a new transcription in Firestore
  Future<void> createTranscription(TranscriptionModel transcription) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updatedTranscription = transcription.copyWith(
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('transcriptions')
          .doc(transcription.id)
          .set(updatedTranscription.toFireStore());
    } catch (e) {
      debugPrint('Error creating transcription: $e');
      rethrow;
    }
  }

  // Update an existing transcription
  Future<void> updateTranscription(TranscriptionModel transcription) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (transcription.userId != userId) {
        throw Exception('Unauthorized access');
      }

      await _firestore
          .collection('transcriptions')
          .doc(transcription.id)
          .update({
        'title': transcription.title,
        'description': transcription.description,
        'content': transcription.content,
        'tags': transcription.tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating transcription: $e');
      rethrow;
    }
  }

  // Just update the title of a transcription
  Future<void> updateTranscriptTitle(String id, String newTitle) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('transcriptions').doc(id).update({
        'title': newTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating transcript title: $e');
      rethrow;
    }
  }

  // Soft-delete a transcription
  Future<void> deleteTranscript(String id) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Soft delete by setting isDeleted to true
      await _firestore.collection('transcriptions').doc(id).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error deleting transcript: $e');
      rethrow;
    }
  }

  // Toggle favorite status of a transcription
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('transcriptions').doc(id).update({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Transcribe an audio file and save it as a new transcription
  Future<Transcript> transcribeAudioFile(String filePath,
      {required String title}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      // Process the recording using our transcription service
      final transcription = await _transcriptionService.processRecording(
        file,
        title,
        userId,
      );

      // Save the transcription to Firestore
      await createTranscription(transcription as TranscriptionModel);

      // Convert TranscriptionModel to Transcript
      return Transcript(
        id: transcription.id,
        title: transcription.title,
        text: transcription.content,
        createdAt: transcription.createdAt,
        userId: transcription.userId,
        updatedAt: transcription.updatedAt,
        duration: transcription.duration,
        content: '',
        audioUrl: '',
        speakers: [],
        tags: [],
      );
    } catch (e) {
      debugPrint('Error transcribing audio file: $e');
      rethrow;
    }
  }

  // Upload and transcribe a video file
  Future<TranscriptModel> transcribeVideoFile(String filePath, String fileName,
      {required String title}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final videoFile = File(filePath);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found');
      }

      // Extract audio from video
      final audioFile =
          await _transcriptionService.extractAudioFromVideo(videoFile);

      // Process the extracted audio
      final transcription = await _transcriptionService.processRecording(
        audioFile,
        title,
        userId,
      );

      // Save the transcription to Firestore
      await createTranscription(transcription as TranscriptionModel);

      // Clean up the extracted audio file
      try {
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } catch (e) {
        // Just log but don't fail if cleanup fails
        debugPrint('Error cleaning up audio file: $e');
      }

      return transcription;
    } catch (e) {
      debugPrint('Error transcribing video file: $e');
      rethrow;
    }
  }

  Widget when(
      {required Center Function() loading,
      required Center Function(dynamic err, dynamic stack) error,
      required Widget Function(dynamic transcripts) data}) {
    // Add a default return or throw statement to ensure the method doesn't complete normally
    throw UnimplementedError('The "when" method is not implemented yet.');
  }
}
