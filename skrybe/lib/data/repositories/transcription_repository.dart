// TODO Implement this library.
// lib/data/repositories/transcription_repository.dart

import 'package:cloud_functions/cloud_functions.dart';

class TranscriptionRepository {
  final FirebaseFunctions _functions;

  TranscriptionRepository(this._functions);

  Future<String> transcribeAudio(String audioUrl) async {
    try {
      final callable = _functions.httpsCallable('transcribeAudio');
      final result = await callable.call({'audioUrl': audioUrl});

      // Check and return the transcription
      final transcription = result.data['transcription'] as String?;
      if (transcription == null) {
        throw 'No transcription returned';
      }

      return transcription;
    } catch (e) {
      // Log or handle error
      rethrow;
    }
  }
}
