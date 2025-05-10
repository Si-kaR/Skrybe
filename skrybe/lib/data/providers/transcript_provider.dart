import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/core/services/transcription_service.dart'
    as core_services;
import 'package:skrybe/data/models/transcription_model.dart';

// Import for error handling and state management
import 'package:skrybe/core/errors/app_error.dart';
import 'package:skrybe/data/repositories/transcription_repository.dart';

// Forward declaration to avoid circular dependencies

/// Repository provider for transcription operations
final transcriptionRepositoryProvider =
    Provider<TranscriptionRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final auth = FirebaseAuth.instance;
  final functions = FirebaseFunctions.instance;
  final transcriptionService =
      ref.watch(core_services.transcriptionServiceProvider);

  return TranscriptionRepository(
    firestore: firestore,
    storage: storage,
    auth: auth,
    functions: functions,
    transcriptionService: transcriptionService,
  );
});

/// Provider that streams all transcriptions for the current user
final transcriptionsStreamProvider =
    StreamProvider<List<TranscriptionModel>>((ref) {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return repository.getAllTranscriptions();
});

/// Provider to get a specific transcription by ID
final transcriptionByIdProvider =
    FutureProvider.family<TranscriptionModel, String>((ref, id) async {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return repository.getTranscriptById(id);
});

/// Provider for favorites-only transcription list
final favoritesTranscriptionsProvider =
    Provider<List<TranscriptionModel>>((ref) {
  final asyncTranscriptions = ref.watch(transcriptionsStreamProvider);

  return asyncTranscriptions.when(
    data: (transcriptions) =>
        transcriptions.where((t) => t.isFavorite).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for recent transcriptions (last 5)
final recentTranscriptionsProvider = Provider<List<TranscriptionModel>>((ref) {
  final asyncTranscriptions = ref.watch(transcriptionsStreamProvider);

  return asyncTranscriptions.when(
    data: (transcriptions) {
      final sorted = List<TranscriptionModel>.from(transcriptions)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted.take(5).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// State notifier provider for transcription creation/processing
final transcriptionProcessingProvider = StateNotifierProvider<
    TranscriptionProcessingNotifier, ResourceState<TranscriptionModel?>>((ref) {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return TranscriptionProcessingNotifier(repository);
});

/// State notifier provider for transcription operations (update, delete)
final transcriptionOperationsProvider =
    StateNotifierProvider<TranscriptionOperationsNotifier, ResourceState<void>>(
        (ref) {
  final repository = ref.watch(transcriptionRepositoryProvider);
  return TranscriptionOperationsNotifier(repository);
});

/// Provider for filtering transcriptions by search term
final searchTranscriptionsProvider =
    StateProvider.family<List<TranscriptionModel>, String>((ref, searchTerm) {
  final lowercaseSearch = searchTerm.toLowerCase();
  final asyncTranscriptions = ref.watch(transcriptionsStreamProvider);

  return asyncTranscriptions.when(
    data: (transcriptions) {
      if (searchTerm.isEmpty) return transcriptions;

      return transcriptions.where((transcript) {
        return transcript.title.toLowerCase().contains(lowercaseSearch) ||
            transcript.content.toLowerCase().contains(lowercaseSearch) ||
            (transcript.summary?.toLowerCase().contains(lowercaseSearch) ??
                false) ||
            transcript.tags!
                .any((tag) => tag.toLowerCase().contains(lowercaseSearch));
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for filtering transcriptions by tag
final tagFilteredTranscriptionsProvider =
    StateProvider.family<List<TranscriptionModel>, String>((ref, tag) {
  final asyncTranscriptions = ref.watch(transcriptionsStreamProvider);

  return asyncTranscriptions.when(
    data: (transcriptions) {
      if (tag.isEmpty) return transcriptions;

      return transcriptions.where((transcript) {
        return transcript.tags!.contains(tag);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for statistics about transcriptions
final transcriptionStatsProvider = Provider<TranscriptionStats>((ref) {
  final asyncTranscriptions = ref.watch(transcriptionsStreamProvider);

  return asyncTranscriptions.when(
    data: (transcriptions) {
      if (transcriptions.isEmpty) {
        return const TranscriptionStats();
      }

      // Calculate total duration
      final totalDuration = transcriptions.fold<Duration>(
          Duration.zero,
          (total, transcript) =>
              total + ((transcript.duration as Duration?) ?? Duration.zero));

      // Get all unique tags
      final allTags = <String>{};
      for (final transcript in transcriptions) {
        allTags.addAll(transcript.tags as Iterable<String>);
      }

      // Calculate average transcript length
      final totalWords = transcriptions.fold<int>(0,
          (total, transcript) => total + transcript.content.split(' ').length);
      final avgWords =
          transcriptions.isEmpty ? 0 : totalWords ~/ transcriptions.length;

      return TranscriptionStats(
        totalCount: transcriptions.length,
        favoriteCount: transcriptions.where((t) => t.isFavorite).length,
        totalDuration: totalDuration,
        uniqueTagsCount: allTags.length,
        avgWordCount: avgWords,
        mostRecentDate: transcriptions.isNotEmpty
            ? transcriptions
                .map((t) => t.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      );
    },
    loading: () => const TranscriptionStats(),
    error: (_, __) => const TranscriptionStats(),
  );
});

/// Statistics class for transcriptions
class TranscriptionStats {
  final int totalCount;
  final int favoriteCount;
  final Duration totalDuration;
  final int uniqueTagsCount;
  final int avgWordCount;
  final DateTime? mostRecentDate;

  const TranscriptionStats({
    this.totalCount = 0,
    this.favoriteCount = 0,
    this.totalDuration = Duration.zero,
    this.uniqueTagsCount = 0,
    this.avgWordCount = 0,
    this.mostRecentDate,
  });

  String get totalTime {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    final seconds = totalDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}


/// Part file implementation for transcript_notifiers.dart
/// This is a placeholder - the actual implementation will be in the separate file