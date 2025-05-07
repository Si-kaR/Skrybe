import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skrybe/data/models/transcript_model.dart';

class TranscriptionDetailScreen extends StatefulWidget {
  final Transcript transcript;

  const TranscriptionDetailScreen({
    Key? key,
    required this.transcript,
    required String transcriptionId,
  }) : super(key: key);

  @override
  _TranscriptionDetailScreenState createState() =>
      _TranscriptionDetailScreenState();
}

class _TranscriptionDetailScreenState extends State<TranscriptionDetailScreen> {
  late TextEditingController _titleController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transcript.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                autofocus: true,
              )
            : Text(widget.transcript.title),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Here you would update the title in your database
                  // For now, we're just updating the local state
                  // widget.transcript.title = _titleController.text;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            Text(
              'Transcript',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.transcript.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.content_copy,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: widget.transcript.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transcript copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  // Implement sharing functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing not implemented yet'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.download,
                label: 'Export',
                onTap: () {
                  // Implement export functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export not implemented yet'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(widget.transcript.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(widget.transcript.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(widget.transcript.duration),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (widget.transcript.audioUrl != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Play Audio'),
                  onPressed: () {
                    // Implement audio playback
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m ${duration.inSeconds.remainder(60)}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Transcript'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement edit functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Transcript'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download Audio'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement download functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transcript'),
          content: const Text(
            'Are you sure you want to delete this transcript? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
                // Here you would delete the transcript
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}
