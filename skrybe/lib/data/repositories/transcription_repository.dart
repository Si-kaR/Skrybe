// // TODO Implement this library.
// // lib/data/repositories/transcription_repository.dart

// import 'package:cloud_functions/cloud_functions.dart';

// class TranscriptionRepository {
//   final FirebaseFunctions _functions;

//   TranscriptionRepository(this._functions);

//   Future<String> transcribeAudio(String audioUrl) async {
//     try {
//       final callable = _functions.httpsCallable('transcribeAudio');
//       final result = await callable.call({'audioUrl': audioUrl});

//       // Check and return the transcription
//       final transcription = result.data['transcription'] as String?;
//       if (transcription == null) {
//         throw 'No transcription returned';
//       }

//       return transcription;
//     } catch (e) {
//       // Log or handle error
//       rethrow;
//     }
//   }
// }
// lib/data/models/transcription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

// lib/data/providers/transcription_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/models/transcription_model.dart';
import 'package:skrybe/data/repositories/transcription_repository.dart';

// lib/data/repositories/transcription_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:skrybe/data/models/transcription_model.dart';
import 'package:skrybe/data/services/transcription_service.dart';
import 'package:uuid/uuid.dart';

class TranscriptionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final TranscriptionService _transcriptionService = TranscriptionService();

  TranscriptionRepository(
      this._firestore, this._storage, this._auth, this._functions);

  Stream<List<TranscriptionModel>> getUserTranscriptions() {
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

  Future<TranscriptionModel> getTranscriptionById(String id) async {
    final doc = await _firestore.collection('transcriptions').doc(id).get();
    if (!doc.exists) {
      throw 'Transcription not found';
    }
    return TranscriptionModel.fromFirestore(doc);
  }

  Future<void> createTranscription(TranscriptionModel transcription) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'User not authenticated';
    }

    final updatedTranscription = transcription.copyWith(
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('transcriptions')
        .doc(transcription.id)
        .set(updatedTranscription.toFirestore());
  }

  Future<void> updateTranscription(TranscriptionModel transcription) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'User not authenticated';
    }

    if (transcription.userId != userId) {
      throw 'Unauthorized access';
    }

    await _firestore.collection('transcriptions').doc(transcription.id).update({
      'title': transcription.title,
      'description': transcription.description,
      'content': transcription.content,
      'tags': transcription.tags,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTranscription(String id) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'User not authenticated';
    }

    // Soft delete by setting isDeleted to true
    await _firestore.collection('transcriptions').doc(id).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'User not authenticated';
    }

    await _firestore.collection('transcriptions').doc(id).update({
      'isFavorite': isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadAudioFile(String filePath, String fileName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'User not authenticated';
    }

    final file = File(filePath);
    final extension = fileName.split('.').last;
    final uniqueFileName = '${const Uuid().v4()}.$extension';
    final storageRef = _storage.ref().child('audio/$userId/$uniqueFileName');

    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'audio/$extension'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> transcribeAudio(String audioUrl) async {
    try {
      final callable = _functions.httpsCallable('transcribeAudio');
      final result = await callable.call({'audioUrl': audioUrl});

      final transcription = result.data['transcription'] as String?;
      if (transcription == null) {
        throw 'No transcription returned';
      }

      return transcription;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadVideoFile(String filePath, String fileName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'User not authenticated';
    }

    final file = File(filePath);
    final extension = fileName.split('.').last;
    final uniqueFileName = '${const Uuid().v4()}.$extension';
    final storageRef = _storage.ref().child('video/$userId/$uniqueFileName');

    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'video/$extension'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
