class Transcript {
  final String id;
  final String title;
  final String text;
  final DateTime createdAt;
  final Duration duration;
  final String? audioUrl;
  final List<TranscriptSegment> segments;
  final TranscriptStatus status;

  Transcript({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
    required this.duration,
    this.audioUrl,
    this.segments = const [],
    this.status = TranscriptStatus.completed,
  });

  // Create a copy of the transcript with modified values
  Transcript copyWith({
    String? id,
    String? title,
    String? text,
    DateTime? createdAt,
    Duration? duration,
    String? audioUrl,
    List<TranscriptSegment>? segments,
    TranscriptStatus? status,
  }) {
    return Transcript(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      segments: segments ?? this.segments,
      status: status ?? this.status,
    );
  }

  // Convert Transcript to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'durationInSeconds': duration.inSeconds,
      'audioUrl': audioUrl,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  // Create a Transcript from a JSON map
  factory Transcript.fromJson(Map<String, dynamic> json) {
    return Transcript(
      id: json['id'],
      title: json['title'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      duration: Duration(seconds: json['durationInSeconds']),
      audioUrl: json['audioUrl'],
      segments: (json['segments'] as List?)
              ?.map((segmentJson) => TranscriptSegment.fromJson(segmentJson))
              .toList() ??
          [],
      status: _parseStatus(json['status']),
    );
  }

  static TranscriptStatus _parseStatus(String status) {
    switch (status) {
      case 'processing':
        return TranscriptStatus.processing;
      case 'failed':
        return TranscriptStatus.failed;
      case 'completed':
      default:
        return TranscriptStatus.completed;
    }
  }
}

class TranscriptSegment {
  final int startTime; // in milliseconds
  final int endTime; // in milliseconds
  final String text;
  final double confidence;

  TranscriptSegment({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.confidence = 1.0,
  });

  // Convert TranscriptSegment to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'text': text,
      'confidence': confidence,
    };
  }

  // Create a TranscriptSegment from a JSON map
  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      startTime: json['startTime'],
      endTime: json['endTime'],
      text: json['text'],
      confidence: json['confidence'] ?? 1.0,
    );
  }
}

enum TranscriptStatus {
  processing,
  completed,
  failed,
}
