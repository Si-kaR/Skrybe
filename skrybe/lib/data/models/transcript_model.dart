import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of the transcript processing
enum TranscriptStatus {
  processing,
  completed,
  failed,
}

/// Represents a segment of a transcript with specific timing information
class TranscriptSegment {
  final int startTime; // in milliseconds
  final int endTime; // in milliseconds
  final String text;
  final String? speaker;
  final double confidence;

  TranscriptSegment({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.speaker,
    this.confidence = 1.0,
  });

  /// Create a copy with modified values
  TranscriptSegment copyWith({
    int? startTime,
    int? endTime,
    String? text,
    String? speaker,
    double? confidence,
  }) {
    return TranscriptSegment(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Convert TranscriptSegment to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'text': text,
      'speaker': speaker,
      'confidence': confidence,
    };
  }

  /// Convert TranscriptSegment to a Firestore map
  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  /// Create a TranscriptSegment from a JSON map
  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      startTime: json['startTime'],
      endTime: json['endTime'],
      text: json['text'],
      speaker: json['speaker'],
      confidence: json['confidence'] ?? 1.0,
    );
  }

  /// Create a TranscriptSegment from a Firestore document
  factory TranscriptSegment.fromFirestore(Map<String, dynamic> data) {
    return TranscriptSegment.fromJson(data);
  }
}

//==========================================================================================================
//
/// Comprehensive transcript model that combines features from multiple sources
class TranscriptModel {
  final String id;
  final String title;
  final String content;
  final String? description;
  final String audioUrl;
  final String? videoUrl;
  final String? summary;
  final List<String> speakers;
  final List<String> tags;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isFavorite;
  final Duration duration;
  final List<TranscriptSegment> segments;
  final TranscriptStatus status;

  TranscriptModel({
    required this.id,
    required this.title,
    required this.content,
    this.description,
    required this.audioUrl,
    this.videoUrl,
    this.summary,
    required this.speakers,
    required this.tags,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isFavorite = false,
    required this.duration,
    this.segments = const [],
    this.status = TranscriptStatus.completed,
  });

  /// Create a copy of this model with some fields updated
  TranscriptModel copyWith({
    String? id,
    String? title,
    String? content,
    String? description,
    String? audioUrl,
    String? videoUrl,
    String? summary,
    List<String>? speakers,
    List<String>? tags,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isFavorite,
    Duration? duration,
    List<TranscriptSegment>? segments,
    TranscriptStatus? status,
  }) {
    return TranscriptModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      summary: summary ?? this.summary,
      speakers: speakers ?? this.speakers,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isFavorite: isFavorite ?? this.isFavorite,
      duration: duration ?? this.duration,
      segments: segments ?? this.segments,
      status: status ?? this.status,
    );
  }

  /// Create a model from a Firestore document
  factory TranscriptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse segments if they exist
    final List<TranscriptSegment> segments = [];
    if (data['segments'] != null && data['segments'] is List) {
      segments.addAll((data['segments'] as List)
          .map((segment) =>
              TranscriptSegment.fromFirestore(segment as Map<String, dynamic>))
          .toList());
    }

    return TranscriptModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      description: data['description'],
      audioUrl: data['audioUrl'] ?? '',
      videoUrl: data['videoUrl'],
      summary: data['summary'],
      speakers: List<String>.from(data['speakers'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
      isFavorite: data['isFavorite'] ?? false,
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      segments: segments,
      status: _parseStatus(data['status']),
    );
  }

  /// Convert this model to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'description': description,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'summary': summary,
      'speakers': speakers,
      'tags': tags,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
      'isFavorite': isFavorite,
      'durationSeconds': duration.inSeconds,
      'segments': segments.map((segment) => segment.toFirestore()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  /// Convert model to JSON format (for APIs or localStorage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'description': description,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'summary': summary,
      'speakers': speakers,
      'tags': tags,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'isFavorite': isFavorite,
      'durationInSeconds': duration.inSeconds,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  /// Create model from JSON format
  factory TranscriptModel.fromJson(Map<String, dynamic> json) {
    return TranscriptModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      description: json['description'],
      audioUrl: json['audioUrl'],
      videoUrl: json['videoUrl'],
      summary: json['summary'],
      speakers: List<String>.from(json['speakers'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDeleted: json['isDeleted'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      duration: Duration(seconds: json['durationInSeconds']),
      segments: (json['segments'] as List?)
              ?.map((segmentJson) => TranscriptSegment.fromJson(segmentJson))
              .toList() ??
          [],
      status: _parseStatus(json['status']),
    );
  }

  /// Helper method to parse status string to enum
  static TranscriptStatus _parseStatus(dynamic status) {
    if (status == null) return TranscriptStatus.completed;

    String statusStr = status.toString();
    if (statusStr.contains('.')) {
      statusStr = statusStr.split('.').last;
    }

    switch (statusStr) {
      case 'processing':
        return TranscriptStatus.processing;
      case 'failed':
        return TranscriptStatus.failed;
      case 'completed':
      default:
        return TranscriptStatus.completed;
    }
  }

  /// Get formatted duration string (MM:SS)
  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get long formatted duration string (HH:MM:SS)
  String get longFormattedDuration {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  /// Get a plaintext representation of the transcript
  String get plainText => content;

  /// Check if the transcript has segments
  bool get hasSegments => segments.isNotEmpty;

  /// Get the transcript text for a specific time position
  String? getTextAtPosition(Duration position) {
    final positionMs = position.inMilliseconds;

    for (final segment in segments) {
      if (positionMs >= segment.startTime && positionMs <= segment.endTime) {
        return segment.text;
      }
    }

    return null;
  }

  /// Find the segment that corresponds to a specific time position
  TranscriptSegment? getSegmentAtPosition(Duration position) {
    final positionMs = position.inMilliseconds;

    for (final segment in segments) {
      if (positionMs >= segment.startTime && positionMs <= segment.endTime) {
        return segment;
      }
    }

    return null;
  }
}

//==========================================================================================================
/// Comprehensive transcript model that combines features from multiple sources
class Transcript {
  final String id;
  final String title;
  final String text;
  final String content;
  final String? description;
  final String audioUrl;
  final String? videoUrl;
  final String? summary;
  final List<String> speakers;
  final List<String> tags;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isFavorite;
  final Duration duration;
  final List<TranscriptSegment> segments;
  final TranscriptStatus status;

  Transcript({
    required this.id,
    required this.title,
    required this.text,
    required this.content,
    this.description,
    required this.audioUrl,
    this.videoUrl,
    this.summary,
    required this.speakers,
    required this.tags,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isFavorite = false,
    required this.duration,
    this.segments = const [],
    this.status = TranscriptStatus.completed,
  });

  /// Create a copy of this model with some fields updated
  Transcript copyWith({
    String? id,
    String? title,
    String? text,
    String? content,
    String? description,
    String? audioUrl,
    String? videoUrl,
    String? summary,
    List<String>? speakers,
    List<String>? tags,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isFavorite,
    Duration? duration,
    List<TranscriptSegment>? segments,
    TranscriptStatus? status,
  }) {
    return Transcript(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      content: content ?? this.content,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      summary: summary ?? this.summary,
      speakers: speakers ?? this.speakers,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isFavorite: isFavorite ?? this.isFavorite,
      duration: duration ?? this.duration,
      segments: segments ?? this.segments,
      status: status ?? this.status,
    );
  }

  /// Create a model from a Firestore document
  factory Transcript.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse segments if they exist
    final List<TranscriptSegment> segments = [];
    if (data['segments'] != null && data['segments'] is List) {
      segments.addAll((data['segments'] as List)
          .map((segment) =>
              TranscriptSegment.fromFirestore(segment as Map<String, dynamic>))
          .toList());
    }

    return Transcript(
      id: doc.id,
      title: data['title'] ?? '',
      text: data['text'],
      content: data['content'] ?? '',
      description: data['description'],
      audioUrl: data['audioUrl'] ?? '',
      videoUrl: data['videoUrl'],
      summary: data['summary'],
      speakers: List<String>.from(data['speakers'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
      isFavorite: data['isFavorite'] ?? false,
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      segments: segments,
      status: _parseStatus(data['status']),
    );
  }

  /// Convert this model to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'description': description,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'summary': summary,
      'speakers': speakers,
      'tags': tags,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
      'isFavorite': isFavorite,
      'durationSeconds': duration.inSeconds,
      'segments': segments.map((segment) => segment.toFirestore()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  /// Convert model to JSON format (for APIs or localStorage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'description': description,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'summary': summary,
      'speakers': speakers,
      'tags': tags,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'isFavorite': isFavorite,
      'durationInSeconds': duration.inSeconds,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  /// Create model from JSON format
  factory Transcript.fromJson(Map<String, dynamic> json) {
    return Transcript(
      id: json['id'],
      title: json['title'],
      text: json['text'],
      content: json['content'],
      description: json['description'],
      audioUrl: json['audioUrl'],
      videoUrl: json['videoUrl'],
      summary: json['summary'],
      speakers: List<String>.from(json['speakers'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDeleted: json['isDeleted'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      duration: Duration(seconds: json['durationInSeconds']),
      segments: (json['segments'] as List?)
              ?.map((segmentJson) => TranscriptSegment.fromJson(segmentJson))
              .toList() ??
          [],
      status: _parseStatus(json['status']),
    );
  }

  /// Helper method to parse status string to enum
  static TranscriptStatus _parseStatus(dynamic status) {
    if (status == null) return TranscriptStatus.completed;

    String statusStr = status.toString();
    if (statusStr.contains('.')) {
      statusStr = statusStr.split('.').last;
    }

    switch (statusStr) {
      case 'processing':
        return TranscriptStatus.processing;
      case 'failed':
        return TranscriptStatus.failed;
      case 'completed':
      default:
        return TranscriptStatus.completed;
    }
  }

  /// Get formatted duration string (MM:SS)
  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get long formatted duration string (HH:MM:SS)
  String get longFormattedDuration {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  /// Get a plaintext representation of the transcript
  String get plainText => content;

  /// Check if the transcript has segments
  bool get hasSegments => segments.isNotEmpty;

  /// Get the transcript text for a specific time position
  String? getTextAtPosition(Duration position) {
    final positionMs = position.inMilliseconds;

    for (final segment in segments) {
      if (positionMs >= segment.startTime && positionMs <= segment.endTime) {
        return segment.text;
      }
    }

    return null;
  }

  /// Find the segment that corresponds to a specific time position
  TranscriptSegment? getSegmentAtPosition(Duration position) {
    final positionMs = position.inMilliseconds;

    for (final segment in segments) {
      if (positionMs >= segment.startTime && positionMs <= segment.endTime) {
        return segment;
      }
    }

    return null;
  }
}
