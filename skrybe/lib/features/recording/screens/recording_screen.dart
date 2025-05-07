import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/core/services/recording_service.dart';
import 'package:skrybe/data/providers/transcript_provider.dart';
import 'package:skrybe/features/transcription/screens/transcription_detail_screen.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with TickerProviderStateMixin {
  final RecordingService _recordingService = RecordingService();
  late AnimationController _pulseController;
  late TextEditingController _titleController;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _titleController = TextEditingController(text: 'New Recording');

    // Start recording when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRecording();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    _durationSubscription?.cancel();
    // Make sure to stop recording if the user navigates away
    if (_isRecording) {
      _stopRecording(canceled: true);
    }
    super.dispose();
  }

  void _startRecording() async {
    try {
      await _recordingService.startRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Listen to duration updates
      _durationSubscription =
          _recordingService.durationStream.listen((duration) {
        setState(() {
          _recordingDuration = duration;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _stopRecording({bool canceled = false}) async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    _durationSubscription?.cancel();

    final recordingPath = await _recordingService.stopRecording();

    if (canceled || recordingPath == null) {
      await _recordingService.deleteRecording();
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // Create a new transcript with the recording
    final repository = ref.read(transcriptionRepositoryProvider);
    final transcript = await repository.transcribeAudioFile(
      recordingPath,
      title: _titleController.text,
    );

    if (!mounted) return;

    if (transcript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process recording'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Navigate to the transcript detail screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TranscriptionDetailScreen(
          transcript: transcript,
          transcriptionId: '',
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelConfirmation();
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildRecordingAnimation(),
            const SizedBox(height: 40),
            Text(
              _formatDuration(_recordingDuration),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 40),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Recording Title',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Spacer(),
            _buildBottomControls(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingAnimation() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.2 + 0.3 * _pulseController.value),
          ),
          child: const Center(
            child: Icon(
              Icons.mic,
              size: 80,
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
            backgroundColor: Colors.red,
          ),
          onPressed: () => _stopRecording(),
          child: const Icon(
            Icons.stop,
            size: 40,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recording?'),
        content: const Text('If you cancel now, your recording will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUE RECORDING'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _stopRecording(canceled: true);
            },
            child: const Text('CANCEL RECORDING'),
          ),
        ],
      ),
    );
  }
}
