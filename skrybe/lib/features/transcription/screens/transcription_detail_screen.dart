// TODO Implement this library.
import 'package:flutter/material.dart';

class TranscriptionDetailScreen extends StatelessWidget {
  final String transcriptionId;

  const TranscriptionDetailScreen({Key? key, required this.transcriptionId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transcription Detail'),
      ),
      body: Center(
        child: Text('Transcription ID: $transcriptionId'),
      ),
    );
  }
}
