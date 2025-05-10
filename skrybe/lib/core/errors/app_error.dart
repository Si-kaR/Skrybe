// lib/data/repositories/transcription_repository.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/models/transcription_model.dart';
import 'package:skrybe/data/repositories/transcription_repository.dart';

/// Helper class for representing application errors
class AppError {
  final String message;
  final dynamic exception;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.exception,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError: $message';
}

/// Generic state class for managing async operations
class ResourceState<T> {
  final bool isLoading;
  final T? data;
  final AppError? error;

  const ResourceState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  factory ResourceState.initial() => ResourceState();

  factory ResourceState.loading() => ResourceState(isLoading: true);

  factory ResourceState.success(T data) => ResourceState(data: data);

  factory ResourceState.error(AppError error) => ResourceState(error: error);

  bool get isInitial => !isLoading && data == null && error == null;
  bool get isSuccess => !isLoading && data != null && error == null;
  bool get isError => !isLoading && error != null;

  ResourceState<T> copyWith({
    bool? isLoading,
    T? data,
    AppError? error,
  }) {
    return ResourceState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

/// State notifier for handling transcription processing operations
class TranscriptionProcessingNotifier
    extends StateNotifier<ResourceState<TranscriptionModel?>> {
  final TranscriptionRepository _repository;

  TranscriptionProcessingNotifier(this._repository)
      : super(ResourceState.initial());

  /// Transcribe an audio file
  Future<void> transcribeAudioFile(String filePath,
      {required String title}) async {
    try {
      state = ResourceState.loading();
      final transcript =
          await _repository.transcribeAudioFile(filePath, title: title);
      state = ResourceState.success(transcript as TranscriptionModel?);
    } catch (e, stackTrace) {
      debugPrint('Error transcribing audio file: $e');
      state = ResourceState.error(
        AppError(
          message: 'Failed to transcribe audio file',
          exception: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Transcribe a video file
  Future<void> transcribeVideoFile(String filePath,
      {required String title}) async {
    try {
      state = ResourceState.loading();
      final transcript =
          await _repository.transcribeVideoFile(filePath, title, title: '');
      // Assuming the repository method returns a TranscriptionModel
      state = ResourceState.success(transcript as TranscriptionModel?);
    } catch (e, stackTrace) {
      debugPrint('Error transcribing video file: $e');
      state = ResourceState.error(
        AppError(
          message: 'Failed to transcribe video file',
          exception: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Reset the state
  void reset() {
    state = ResourceState.initial();
  }
}

/// State notifier for handling transcription operations (update, delete, etc.)
class TranscriptionOperationsNotifier
    extends StateNotifier<ResourceState<void>> {
  final TranscriptionRepository _repository;

  TranscriptionOperationsNotifier(this._repository)
      : super(ResourceState.initial());

  /// Update a transcription
  Future<void> updateTranscription(TranscriptionModel transcription) async {
    try {
      state = ResourceState.loading();
      await _repository.updateTranscription(transcription);
      state = ResourceState.success(null);
    } catch (e, stackTrace) {
      debugPrint('Error updating transcription: $e');
      state = ResourceState.error(
        AppError(
          message: 'Failed to update transcription',
          exception: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Update just the title of a transcription
  Future<void> updateTranscriptTitle(String id, String newTitle) async {
    try {
      state = ResourceState.loading();
      await _repository.updateTranscriptTitle(id, newTitle);
      state = ResourceState.success(null);
    } catch (e, stackTrace) {
      debugPrint('Error updating transcript title: $e');
      state = ResourceState.error(
        AppError(
          message: 'Failed to update transcript title',
          exception: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Delete a transcription
  Future<void> deleteTranscript(String id) async {
    try {
      state = ResourceState.loading();
      await _repository.deleteTranscript(id);
      state = ResourceState.success(null);
    } catch (e, stackTrace) {
      debugPrint('Error deleting transcript: $e');
      state = ResourceState.error(
        AppError(
          message: 'Failed to delete transcript',
          exception: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      state = ResourceState.loading();
      await _repository.toggleFavorite(id, isFavorite);
      state = ResourceState.success(null);
    } catch (e, stackTrace) {
      debugPrint('Error toggling favorite status: $e');
      state = ResourceState.error(
        AppError(
          message: 'Failed to update favorite status',
          exception: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Reset the operation state
  void reset() {
    state = ResourceState.initial();
  }
}
