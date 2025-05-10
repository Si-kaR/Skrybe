import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skrybe/core/services/recording_service.dart';
import 'package:skrybe/data/providers/transcript_provider.dart';
import 'package:skrybe/features/transcription/screens/transcription_detail_screen.dart';
import 'package:skrybe/features/dashboard/screens/dashboard_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with TickerProviderStateMixin {
  final RecordingService _recordingService = RecordingService();
  late TextEditingController _titleController;
  bool _isRecording = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isFinishedRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _amplitudeSubscription;
  List<double> _amplitudeData = List.generate(60, (_) => 0.0);

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _morphController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Constants
  final int _maxAmplitude = 100;
  final double _minBubbleSize = 60.0;
  final double _maxBubbleSize = 120.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'New Recording');

    // Setup animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Load the beep sound
    _loadSounds();

    // Check microphone permissions when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMicrophonePermission();
    });
  }

  Future<void> _loadSounds() async {
    // In a real implementation, you'd load your custom sounds from assets
    // For this example, we'll use default sounds
  }

  Future<void> _playBeepSound() async {
    try {
      // For now, we'll use a system beep, but you should replace this with a custom sound
      await HapticFeedback.heavyImpact();
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _morphController.dispose();
    _titleController.dispose();
    _durationSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _audioPlayer.dispose();

    // Make sure to stop recording if the user navigates away
    if (_isRecording) {
      _stopRecording(canceled: true);
    }
    super.dispose();
  }

  Future<void> _checkMicrophonePermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final status = await Permission.microphone.status;

    setState(() {
      _hasPermission = status.isGranted;
      _isCheckingPermission = false;
    });
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    setState(() {
      _hasPermission = status.isGranted;
    });

    if (status.isGranted) {
      _startRecording();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for recording'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _requestMicrophonePermission();
      return;
    }

    try {
      final recordingPath = await _recordingService.startRecording();
      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _isFinishedRecording = false;
        _recordingDuration = Duration.zero;
        _recordingPath = recordingPath;
      });

      // Listen to duration updates
      _durationSubscription =
          _recordingService.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _recordingDuration = duration;
          });
        }
      });

      // Listen to amplitude updates for waveform
      _amplitudeSubscription =
          _recordingService.amplitudeStream?.listen((amplitude) {
        if (mounted) {
          setState(() {
            // Normalize amplitude (adjust as needed)
            double normalizedValue =
                (amplitude / _maxAmplitude).clamp(0.1, 1.0);

            // Add new amplitude data and remove oldest
            _amplitudeData.removeAt(0);
            _amplitudeData.add(normalizedValue);
          });
        }
      });

      // Start the morph animation
      _morphController.repeat(reverse: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopRecording({bool canceled = false}) async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    _durationSubscription?.cancel();
    _durationSubscription = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    // Stop animations
    _morphController.stop();

    try {
      final recordingPath = await _recordingService.stopRecording();

      // Play the completion sound
      await _playBeepSound();

      if (canceled || recordingPath == null) {
        await _recordingService.deleteRecording();
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      setState(() {
        _isFinishedRecording = true;
        _recordingPath = recordingPath;
      });

      // Don't immediately process here - wait for user decision
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping recording: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _processRecording(RecordingAction action) async {
    if (_recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recording available to process'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    switch (action) {
      case RecordingAction.transcribe:
        try {
          final repository = ref.read(transcriptionRepositoryProvider);
          final transcript = await repository.transcribeAudioFile(
            _recordingPath!,
            title: _titleController.text,
          );

          if (!mounted) return;

          if (transcript == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to transcribe recording'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          // Navigate to the transcript detail screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TranscriptionDetailScreen(
                transcript: transcript,
                transcriptionId: transcript.id,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to transcribe: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;

      case RecordingAction.save:
        try {
          // Get the app's documents directory
          final directory = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final savedPath =
              '${directory.path}/recordings/${_titleController.text}_$timestamp.m4a';

          // Request storage permission if needed
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            throw 'Storage permission required to save recording';
          }

          // Save the file (in a real implementation, copy from temp location to permanent storage)
          // For this example, we'll just simulate success

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording saved successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const DashboardScreen(child: SizedBox())),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save recording: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;

      case RecordingAction.discard:
        _showDiscardConfirmation();
        break;

      case RecordingAction.newRecording:
        // Reset state and start a new recording
        setState(() {
          _isFinishedRecording = false;
          _recordingPath = null;
          _recordingDuration = Duration.zero;
          _titleController.text = 'New Recording';
        });
        break;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_isRecording) {
              _showCancelConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isCheckingPermission
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission && !_isRecording
              ? _buildPermissionRequest()
              : _isFinishedRecording
                  ? _buildPostRecordingOptions(colorScheme)
                  : _buildRecordingContent(colorScheme),
    );
  }

  Widget _buildRecordingContent(ColorScheme colorScheme) {
    return Center(
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Audio visualization
          _buildAudioVisualization(colorScheme),
          const Spacer(flex: 1),
          // Timer
          Text(
            _formatDuration(_recordingDuration),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(flex: 1),
          // Recording title
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Recording Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
          ),
          const Spacer(flex: 2),
          // Record/Stop button
          _buildRecordButton(colorScheme),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildPostRecordingOptions(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Recording Complete',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(_recordingDuration),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          // Title display/edit
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Recording Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.text_fields,
                  label: 'Transcribe',
                  color: colorScheme.primary,
                  onPressed: () =>
                      _processRecording(RecordingAction.transcribe),
                ),
                _buildActionButton(
                  icon: Icons.save,
                  label: 'Save',
                  color: Colors.green,
                  onPressed: () => _processRecording(RecordingAction.save),
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Discard',
                  color: Colors.red,
                  onPressed: () => _processRecording(RecordingAction.discard),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // New recording button
          ElevatedButton.icon(
            icon: const Icon(Icons.mic),
            label: const Text('New Recording'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _processRecording(RecordingAction.newRecording),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.mic_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Microphone Permission Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Skrybe needs access to your microphone to record audio for transcription.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.mic),
            label: const Text('Grant Microphone Access'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _requestMicrophonePermission,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioVisualization(ColorScheme colorScheme) {
    return SizedBox(
      height: 200,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base circle that pulses
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: _minBubbleSize * 2.0,
                  height: _minBubbleSize * 2.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 10 * _pulseAnimation.value,
                        spreadRadius: 5 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Dynamic visualization based on amplitude
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isRecording ? _getWaveSize() : _minBubbleSize * 1.5,
              height: _isRecording ? _getWaveSize() : _minBubbleSize * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.7),
              ),
            ),

            // Morphing wave effect (circular wave)
            if (_isRecording) ..._generateWaveCircles(colorScheme),

            // Microphone icon in center
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  double _getWaveSize() {
    // Calculate the current wave size based on recent amplitude values
    double averageAmplitude = _amplitudeData
            .sublist(
                Math.max(0, (_amplitudeData.length - 5).toDouble()).toInt())
            .reduce((a, b) => a + b) /
        Math.min(5.toDouble(), _amplitudeData.length.toDouble());

    return _minBubbleSize +
        (averageAmplitude * (_maxBubbleSize - _minBubbleSize));
  }

  List<Widget> _generateWaveCircles(ColorScheme colorScheme) {
    // Create multiple circular waves that expand outward
    final List<Widget> circles = [];
    final int numCircles = 3;

    for (int i = 0; i < numCircles; i++) {
      // Use different phases of the animation for each circle
      final double phase = i / numCircles;
      circles.add(
        AnimatedBuilder(
          animation: _morphController,
          builder: (context, child) {
            // Calculate a value between 0 and 1 for this circle's current animation state
            final double value = ((_morphController.value + phase) % 1.0);

            // Only show circles in the active phase
            if (value < 0.1) return const SizedBox.shrink();

            // Size grows with the animation progress
            final double size = _maxBubbleSize * 2.0 + (value * 120);

            // Opacity decreases as the circle expands
            final double opacity = (1.0 - value) * 0.5;

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      colorScheme.primary.withOpacity(Math.min(opacity, 0.6)),
                  width: 2,
                ),
              ),
            );
          },
        ),
      );
    }

    return circles;
  }

  Widget _buildRecordButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? Colors.red : colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : colorScheme.primary)
                  .withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isRecording
                ? const Icon(Icons.stop, color: Colors.white, size: 40)
                : const Icon(Icons.mic, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recording?'),
        content: const Text('If you cancel now, your recording will be lost.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog only
            child: const Text('CONTINUE RECORDING'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              _stopRecording(canceled: true); // Then handle the cancellation
            },
            child: const Text('CANCEL RECORDING'),
          ),
        ],
      ),
    );
  }

  void _showDiscardConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text(
          'Are you sure you want to discard this recording? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('KEEP'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete the recording file
              if (_recordingPath != null) {
                _recordingService.deleteRecording();
              }
              // Navigate back to dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const DashboardScreen(child: SizedBox())),
              );
            },
            child: const Text('DISCARD'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

// For handling the different action types
enum RecordingAction {
  transcribe,
  save,
  discard,
  newRecording,
}

// Math utility class for calculations
class Math {
  static double min(double a, double b) => a < b ? a : b;
  static double max(double a, double b) => a > b ? a : b;
}
