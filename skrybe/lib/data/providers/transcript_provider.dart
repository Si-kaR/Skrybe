import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/models/transcript_model.dart';
import 'package:skrybe/data/repositories/transcription_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Provider to fetch a single transcript by ID
final transcriptProvider =
    FutureProvider.family<Transcript, String>((ref, id) async {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return repository.getTranscriptById(id);
});

// Provider for all transcripts
final transcriptsProvider = FutureProvider<List<Transcript>>((ref) async {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return repository.getAllTranscriptions();
});

// State notifier for transcript updates
class TranscriptUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final TranscriptionRepository _repository;

  TranscriptUpdateNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<void> updateTitle(String id, String newTitle) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTranscriptTitle(id, newTitle);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final transcriptUpdateProvider =
    StateNotifierProvider<TranscriptUpdateNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return TranscriptUpdateNotifier(repository);
});

// State notifier for transcript deletion
class TranscriptDeleteNotifier extends StateNotifier<AsyncValue<void>> {
  final TranscriptionRepository _repository;

  TranscriptDeleteNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<void> deleteTranscript(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTranscript(id);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final transcriptDeleteProvider =
    StateNotifierProvider<TranscriptDeleteNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return TranscriptDeleteNotifier(repository);
});

// Repository provider
final transcriptionRepositoryProvider =
    Provider<TranscriptionRepository>((ref) {
  return TranscriptionRepository(
      FirebaseFirestore.instance,
      FirebaseStorage.instance,
      FirebaseAuth.instance,
      FirebaseFunctions.instance);
});
