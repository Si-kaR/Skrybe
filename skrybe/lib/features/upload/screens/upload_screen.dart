// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:skrybe/data/providers/transcript_provider.dart';
// import 'package:skrybe/features/transcription/screens/transcription_detail_screen.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:skrybe/data/providers/transcript_provider.dart';
import 'package:skrybe/features/transcription/screens/transcription_detail_screen.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    // Automatically open file picker when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickFile();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.first.name.split('.').first;
        }
      });
    } else {
      // User canceled the file picker
      if (!mounted) return;
      setState(() {
        _selectedFile = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate upload progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _uploadProgress = i / 10;
        });
      }

      // Process the file
      final repository = ref.read(transcriptionRepositoryProvider);
      final transcript = await repository.transcribeAudioFile(
        _selectedFile!.path,
        title: _titleController.text,
      );

      if (!mounted) return;

      if (transcript != null) {
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
      } else {
        _showErrorDialog('Failed to process audio file');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Audio File'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedFile != null) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.audio_file,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(File(_selectedFile!.path).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _isUploading ? null : _pickFile,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Title',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter title for transcription',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isUploading,
              ),
              const SizedBox(height: 32),
              if (_isUploading) ...[
                const Text('Processing audio file...'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Text('${(_uploadProgress * 100).toInt()}%'),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                      _isUploading ? 'Processing...' : 'Start Transcription'),
                ),
              ),
            ] else ...[
              const Center(
                child: Text('Please select an audio file to upload.'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// class UploadScreen extends ConsumerStatefulWidget {
//   const UploadScreen({Key? key}) : super(key: key);

//   @override
//   _UploadScreenState createState() => _UploadScreenState();
// }

// class _UploadScreenState extends ConsumerState<UploadScreen> {
//   File? _selectedFile;
//   bool _isUploading = false;
//   double _uploadProgress = 0.0;
//   late TextEditingController _titleController;

//   @override
//   void initState() {
//     super.initState();
//     _titleController = TextEditingController();

//     // Automatically open file picker when screen loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _pickFile();
//     });
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.audio,
//       allowMultiple: false,
//     );

//     if (result != null && result.files.isNotEmpty) {
//       setState(() {
//         _selectedFile = File(result.files.first.path!);
//         if (_titleController.text.isEmpty) {
//           _titleController.text = result.files.first.name.split('.').first;
//         }
//       });
//     } else {
//       // User canceled the file picker
//       if (!mounted) return;
//       Navigator.pop(context);
//     }
//   }

//   Future<void> _uploadFile() async {
//     if (_selectedFile == null) return;

//     setState(() {
//       _isUploading = true;
//       _uploadProgress = 0.0;
//     });

//     try {
//       // Simulate upload progress
//       for (int i = 1; i <= 10; i++) {
//         await Future.delayed(const Duration(milliseconds: 300));
//         setState(() {
//           _uploadProgress = i / 10;
//         });
//       }

//       // Process the file
//       final repository = ref.read(transcriptionRepositoryProvider);
//       final transcript = await repository.transcribeAudioFile(
//         _selectedFile!.path,
//         title: _titleController.text,
//       );

//       if (!mounted) return;

//       if (transcript != null) {
//         // Navigate to the transcript detail screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) =>
//                 TranscriptionDetailScreen(transcript: transcript),
//           ),
//         );
//       } else {
//         _showErrorDialog('Failed to process audio file');
//       }
//     } catch (e) {
//       if (!mounted) return;
//       _showErrorDialog('Error: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isUploading = false;
//         });
//       }
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // Close dialog
//               Navigator.pop(context); // Go back to previous screen
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Upload Audio File'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (_selectedFile != null) ...[
//               Card(
//                 margin: EdgeInsets.zero,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: Theme.of(context).colorScheme.primaryContainer,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(
//                           Icons.audio_file,
//                           color: Theme.of(context).colorScheme.primary,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _selectedFile!.path.split('/').last,
//                               style: Theme.of(context).textTheme.titleMedium,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${(File(_selectedFile!.path).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
//                               style: Theme.of(context).textTheme.bodySmall,
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.refresh),
//                         onPressed: _isUploading ? null : _pickFile,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Title',
//                 style: Theme.of(context).textTheme.titleSmall,
//               ),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _titleController,
//                 decoration: const InputDecoration(
//                   hintText: 'Enter title for transcription',
//                   border: OutlineInputBorder(),
//                 ),
//                 enabled: !_isUploading,
//               ),
//               const SizedBox(height: 32),
//               if (_isUploading) ...[
//                 const Text('Processing audio file...'),
//                 const SizedBox(height: 8),
//                 LinearProgressIndicator(value: _uploadProgress),
//                 const SizedBox(height: 8),
//                 Text('${(_uploadProgress * 100).toInt()}%'),
//               ],
//               const Spacer(),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isUploading ? null : _uploadFile,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: Text(
//                       _isUploading ? 'Processing...' : 'Start Transcription'),
//                 ),
//               ),
//             ] else ...[
//               const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
