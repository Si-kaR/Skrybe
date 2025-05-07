// lib/data/models/transcription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

// lib/data/providers/transcription_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/repositories/transcription_repository.dart';

enum TranscriptionStatus {
  pending,
  processing,
  completed,
  failed,
}

enum TranscriptionSource {
  recording,
  audioUpload,
  videoUpload,
}

class TranscriptionModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String content;
  final String? rawaudioUrl;
  final String? rawvideoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final TranscriptionStatus status;
  final TranscriptionSource source;
  final double? duration;
  final List<String>? speakers;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  final bool isFavorite;
  final bool isSynced;
  final bool isDeleted;
  final String? errorMessage;

  const TranscriptionModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.content,
    this.rawaudioUrl,
    this.rawvideoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.source,
    this.duration,
    this.speakers,
    this.metadata,
    this.tags,
    this.isSynced = false,
    this.isFavorite = false,
    this.isDeleted = false,
    this.errorMessage,
  });

  factory TranscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TranscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Untitled Transcription',
      description: data['description'],
      content: data['content'] ?? '',
      rawaudioUrl: data['rawaudioUrl'],
      rawvideoUrl: data['rawvideoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: TranscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TranscriptionStatus.pending,
      ),
      source: TranscriptionSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => TranscriptionSource.recording,
      ),
      duration: data['durationMs'],
      speakers:
          data['speakers'] != null ? List<String>.from(data['speakers']) : null,
      metadata: data['metadata'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      isSynced: data['isSynced'] ?? false,
      errorMessage: data['errorMessage'],
      isFavorite: data['isFavorite'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  factory TranscriptionModel.fromLocal(Map<String, dynamic> data) {
    return TranscriptionModel(
      id: data['id'],
      userId: data['userId'],
      title: data['title'] ?? 'Untitled Transcription',
      description: data['description'],
      content: data['content'] ?? '',
      rawaudioUrl: data['rawaudioUrl'],
      rawvideoUrl: data['rawvideoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: TranscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TranscriptionStatus.pending,
      ),
      source: TranscriptionSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => TranscriptionSource.recording,
      ),
      duration: data['durationMs'] != null ? data['durationMs'] / 1000 : null,
      speakers:
          data['speakers'] != null ? List<String>.from(data['speakers']) : null,
      metadata: data['metadata'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      isSynced: data['isSynced'] ?? false,
      errorMessage: data['errorMessage'],
      isFavorite: data['isFavorite'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFireStore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'content': content,
      'source': source.name,
      'status': status.name,
      'rawaudioUrl': rawaudioUrl,
      'rawvideoUrl': rawvideoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt!),
      'metadata': metadata,
      'durationMs': duration != null ? duration! * 1000 : null,
      'speakers': speakers,
      'isSynced': isSynced,
      'errorMessage': errorMessage,
      'tags': tags,
      'isFavorite': isFavorite,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toLocal() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'content': content,
      'source': source.name,
      'status': status.name,
      'rawaudioUrl': rawaudioUrl,
      'rawvideoUrl': rawvideoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'durationMs': duration != null ? duration! * 1000 : null,
      'speakers': speakers,
      'isSynced': isSynced,
      'errorMessage': errorMessage,
      'tags': tags,
      'isFavorite': isFavorite,
      'isDeleted': isDeleted,
    };
  }

  factory TranscriptionModel.empty() {
    return TranscriptionModel(
      id: const Uuid().v4(),
      userId: '',
      title: 'Untitled Transcription',
      content: '',
      source: TranscriptionSource.recording,
      status: TranscriptionStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
    String? rawaudioUrl,
    String? rawvideoUrl,
    Duration? duration,
    List<String>? speakers,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isSynced,
    String? errorMessage,
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
      rawaudioUrl: rawaudioUrl ?? this.rawaudioUrl,
      rawvideoUrl: rawvideoUrl ?? this.rawvideoUrl,
      duration: duration as double? ?? this.duration,
      speakers: speakers ?? this.speakers,
      isSynced: isSynced ?? this.isSynced,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
    );
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
        rawaudioUrl,
        rawvideoUrl,
        duration,
        createdAt,
        updatedAt,
        metadata,
        speakers,
        isSynced,
        errorMessage,
        tags,
        isFavorite,
        isDeleted,
      ];

  // Map<String, dynamic> toFirestore() {
  //   return {
  //     'userId': userId,
  //     'title': title,
  //     'description': description,
  //     'content': content,
  //     'source': source.name,
  //     'status': status.name,
  //     'audioUrl': rawaudioUrl,
  //     'videoUrl': rawvideoUrl,
  //     'duration': duration,
  //     'createdAt': FieldValue.serverTimestamp(),
  //     'updatedAt': FieldValue.serverTimestamp(),
  //     'metadata': metadata,
  //     // // 'tags': tags,
  //     'isFavorite': isFavorite,
  //     'isDeleted': isDeleted,
  //   };
  // }

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
      rawaudioUrl: map['rawaudioUrl'],
      rawvideoUrl: map['rawvideoUrl'],
      duration: map['duration'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      metadata: map['metadata'],
      // // // tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
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
    if (duration == null) return '';
    final minutes = (duration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration! % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
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
  return transcriptionRepository
      .getTranscriptionById(id)
      .then((value) => value);
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
