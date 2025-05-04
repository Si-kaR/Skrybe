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

enum TranscriptionSource {
  recording,
  audioUpload,
  videoUpload,
}

enum TranscriptionStatus {
  pending,
  processing,
  completed,
  failed,
}

class TranscriptionModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String content;
  final TranscriptionSource source;
  final TranscriptionStatus status;
  final String? audioUrl;
  final String? videoUrl;
  final double? durationInSeconds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  final bool isFavorite;
  final bool isDeleted;

  const TranscriptionModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.content,
    required this.source,
    required this.status,
    this.audioUrl,
    this.videoUrl,
    this.durationInSeconds,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.tags,
    this.isFavorite = false,
    this.isDeleted = false,
  });

  factory TranscriptionModel.empty() {
    return TranscriptionModel(
      id: const Uuid().v4(),
      userId: '',
      title: 'Untitled Transcription',
      content: '',
      source: TranscriptionSource.recording,
      status: TranscriptionStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  TranscriptionModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? content,
    TranscriptionSource? source,
    TranscriptionStatus? status,
    String? audioUrl,
    String? videoUrl,
    double? durationInSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isFavorite,
    bool? isDeleted,
  }) {
    return TranscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      source: source ?? this.source,
      status: status ?? this.status,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'content': content,
      'source': source.name,
      'status': status.name,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'durationInSeconds': durationInSeconds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'tags': tags,
      'isFavorite': isFavorite,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'content': content,
      'source': source.name,
      'status': status.name,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'durationInSeconds': durationInSeconds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
      'tags': tags,
      'isFavorite': isFavorite,
      'isDeleted': isDeleted,
    };
  }

  factory TranscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TranscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Untitled Transcription',
      description: data['description'],
      content: data['content'] ?? '',
      source: TranscriptionSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => TranscriptionSource.recording,
      ),
      status: TranscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TranscriptionStatus.pending,
      ),
      audioUrl: data['audioUrl'],
      videoUrl: data['videoUrl'],
      durationInSeconds: data['durationInSeconds'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      isFavorite: data['isFavorite'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  factory TranscriptionModel.fromMap(Map<String, dynamic> map) {
    return TranscriptionModel(
      id: map['id'] ?? const Uuid().v4(),
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Transcription',
      description: map['description'],
      content: map['content'] ?? '',
      source: TranscriptionSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => TranscriptionSource.recording,
      ),
      status: TranscriptionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TranscriptionStatus.pending,
      ),
      audioUrl: map['audioUrl'],
      videoUrl: map['videoUrl'],
      durationInSeconds: map['durationInSeconds'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      metadata: map['metadata'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      isFavorite: map['isFavorite'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  String get sourceDisplay {
    switch (source) {
      case TranscriptionSource.recording:
        return 'Recorded';
      case TranscriptionSource.audioUpload:
        return 'Audio Upload';
      case TranscriptionSource.videoUpload:
        return 'Video Upload';
    }
  }

  String get statusDisplay {
    switch (status) {
      case TranscriptionStatus.pending:
        return 'Pending';
      case TranscriptionStatus.processing:
        return 'Processing';
      case TranscriptionStatus.completed:
        return 'Completed';
      case TranscriptionStatus.failed:
        return 'Failed';
    }
  }

  String get formattedDuration {
    if (durationInSeconds == null) return '';
    final minutes = (durationInSeconds! ~/ 60).toString().padLeft(2, '0');
    final seconds =
        (durationInSeconds! % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        content,
        source,
        status,
        audioUrl,
        videoUrl,
        durationInSeconds,
        createdAt,
        updatedAt,
        metadata,
        tags,
        isFavorite,
        isDeleted,
      ];
}

final transcriptionRepositoryProvider =
    Provider<TranscriptionRepository>((ref) {
  return TranscriptionRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    FirebaseAuth.instance,
    FirebaseFunctions.instance,
  );
});

final userTranscriptionsProvider =
    StreamProvider<List<TranscriptionModel>>((ref) {
  final transcriptionRepository = ref.watch(transcriptionRepositoryProvider);
  return transcriptionRepository.getUserTranscriptions();
});

final transcriptionControllerProvider =
    StateNotifierProvider<TranscriptionController, AsyncValue<void>>((ref) {
  final transcriptionRepository = ref.watch(transcriptionRepositoryProvider);
  return TranscriptionController(
      transcriptionRepository: transcriptionRepository);
});

final transcriptionDetailProvider =
    FutureProvider.family<TranscriptionModel, String>((ref, id) {
  final transcriptionRepository = ref.watch(transcriptionRepositoryProvider);
  return transcriptionRepository.getTranscriptionById(id);
});

class TranscriptionController extends StateNotifier<AsyncValue<void>> {
  final TranscriptionRepository _transcriptionRepository;

  TranscriptionController({
    required TranscriptionRepository transcriptionRepository,
  })  : _transcriptionRepository = transcriptionRepository,
        super(const AsyncValue.data(null));

  Future<void> createTranscription(TranscriptionModel transcription) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _transcriptionRepository.createTranscription(transcription));
  }

  Future<void> updateTranscription(TranscriptionModel transcription) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _transcriptionRepository.updateTranscription(transcription));
  }

  Future<void> deleteTranscription(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _transcriptionRepository.deleteTranscription(id));
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _transcriptionRepository.toggleFavorite(id, isFavorite));
  }

  Future<String> uploadAudioFile(String filePath, String fileName) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => _transcriptionRepository.uploadAudioFile(filePath, fileName));
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
    return result.value!;
  }

  Future<String> uploadVideoFile(String filePath, String fileName) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => _transcriptionRepository.uploadVideoFile(filePath, fileName));
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
    return result.value!;
  }

  // Future<String> transcribeAudio(String audioUrl) async {
  //   state = const AsyncValue.loading();
  //   final result = await AsyncValue.guard(
  //       () => _transcriptionRepository.transcribeAudio(audioUrl));
  //   state = result;
  //   if (result.hasError) {
  //     throw result.error!;
  //   }
  //   return result.value!;
  // }
  Future<String> transcribeAudio(String audioUrl) async {
    state = const AsyncValue.loading();
    try {
      final result = await _transcriptionRepository.transcribeAudio(audioUrl);
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // Log the error for debugging purposes
      print('Error during audio transcription: $error');
      print('Stack trace: $stackTrace');
      rethrow; // Re-throw the error to allow further handling if needed
    }
  }
}
